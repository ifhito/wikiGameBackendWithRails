require 'rails_helper'

RSpec.describe WikiGameChannel, type: :channel do

  # before do
  #   @chat_group = create(:chat_group)
  #   stub_connection 
  # end

  describe 'メッセージの送信' do

    context '送信成功' do
      subject do
        # `subscribe`ヘルパーは、記載されているチャンネルへ
        # のサブスクライブアクションを実行する
        subscribe(room: 'test', name: 'testuser')
        # `subscription`はサブスクライブされたチャネルのインスタンス
        subscription
      end
      it '部屋にユーザが追加されると、redisに部屋とユーザが追加される' do
        subscribe(room: 'test', name: 'testuser')
        expect($redis.lrange('test', 0, -1)).to eq ['testuser']
        expect($redis.keys('*')).to eq ['test']
      end

      it '部屋が作成されるとそのユーザの答えのタイトル、接続の数、部屋のID, 参加者名がブロードキャストされる' do
        expect{subject}.to have_broadcasted_to('wikigame_channel_test').with{ |data|
          expect(data['message']['connectNumber']).to eq 1
          expect(data['message']['answerTitle']).to_not eq ''
          expect(data['message']['roomId']).to_not eq ''
        }
      end
      # {'data': html, 'nextNumber':0, 'nextName': name_list[0]}
      it 'ゲームがスタートするとシードのHTML、現在の参加者の数、name_listの初めの名前が次のユーザとして追加される' do
        subscribe(room: 'test', name: 'testuser')
        subscribe(room: 'test', name: 'testuser2')
        expect do perform :start_game, message: {
          command: 'message',
          identifier: {
            channel: 'WikiGameChannel',
            room: 'test',
            name: 'testuser'
        },
          data: {action: 'start_game'}
          }
        end .to have_broadcasted_to('wikigame_channel_test').with{ |data|
         expect(data['message']['data']).to_not eq ''
         expect(data['message']['nextNumber']).to eq 0
         name_list = SubscriberTracker.sub_get_list('test')
         expect(data['message']['nextName']).to eq name_list[0]
        }
      end

      it 'send_urlが呼ばれた場合、渡されたURLのHTMLと次の名前、次の数字が渡される' do
        subscribe(room: 'test', name: 'testuser')
        subscribe(room: 'test', name: 'testuser2')
        expect do perform :send_url, title: '桃太郎', myNumber: 0, nextNumber: 0
        end .to have_broadcasted_to('wikigame_channel_test').with{ |data|
          name_list = SubscriberTracker.sub_get_list('test')
          agent = Mechanize.new
          page = agent.get("https://ja.wikipedia.org/wiki/桃太郎")
          html = page.content.force_encoding("UTF-8")
          expect(data['message']['data']).to eq html
          expect(data['message']['nextNumber']).to eq 1
          expect(data['message']['nextName']).to eq name_list[1]
        }
      end

      it 'decied_winnerが決まると勝利者の名前が渡される' do
        subscribe(room: 'test', name: 'testuser')
        subscribe(room: 'test', name: 'testuser2')
        expect do perform :decied_winner, name: "testuser"
        end .to have_broadcasted_to('wikigame_channel_test').with{ |data|
          expect(data['message']['winner']).to eq "testuser"
          expect($redis.keys('*')).to eq []
        }
      end

      it 'delete_userが呼ばれると、渡されたデータのユーザがredisから削除される' do
        room = 'test'
        user1 = {name: 'testuser', num: 0}
        user2 = {name: 'testuser2', num: 1}
        user3 = {name: 'testuser3', num: 2}
        subscribe(room: room, name: user1[:name])
        subscribe(room: room, name: user2[:name])
        subscribe(room: room, name: user3[:name])
        expect do perform :delete_user, myName: 'testuser2', nowName: 'testuser', nextNumber: user1[:num]
        end .to have_broadcasted_to('wikigame_channel_test').with{ |data|
          expect(data['message']['nextNumber']).to eq 0
          expect(data['message']['nextName']).to eq 'testuser'
          name_list = SubscriberTracker.sub_get_list('test')
          expect(name_list).to eq ['testuser', 'testuser3']
          expect($redis.keys('*')).to eq ["test"]
        }
      end

      it 'delete_userで今のユーザが削除されると次のユーザに順番が変更になる。' do
        room = 'test'
        user1 = {name: 'testuser', num: 0}
        user2 = {name: 'testuser2', num: 1}
        user3 = {name: 'testuser3', num: 2}
        subscribe(room: room, name: user1[:name])
        subscribe(room: room, name: user2[:name])
        subscribe(room: room, name: user3[:name])
        expect do perform :delete_user, myName: 'testuser', nowName: 'testuser', nextNumber: user1[:num]
        end .to have_broadcasted_to('wikigame_channel_test').with{ |data|
          expect(data['message']['nextNumber']).to eq 0
          expect(data['message']['nextName']).to eq 'testuser2'
          name_list = SubscriberTracker.sub_get_list('test')
          expect(name_list).to eq ['testuser2', 'testuser3']
          expect($redis.keys('*')).to eq ["test"]
        }
      end

      it 'delete_userで削除されたユーザが最後で今のユーザの場合、一番初めのユーザに順番が移る' do
        room = 'test'
        user1 = {name: 'testuser', num: 0}
        user2 = {name: 'testuser2', num: 1}
        user3 = {name: 'testuser3', num: 2}
        subscribe(room: room, name: user1[:name])
        subscribe(room: room, name: user2[:name])
        subscribe(room: room, name: user3[:name])
        expect do perform :delete_user, myName: 'testuser3', nowName: 'testuser3', nextNumber: user3[:num]
        end .to have_broadcasted_to('wikigame_channel_test').with{ |data|
          expect(data['message']['nextNumber']).to eq 0
          expect(data['message']['nextName']).to eq 'testuser'
          name_list = SubscriberTracker.sub_get_list('test')
          expect(name_list).to eq ['testuser', 'testuser2']
          expect($redis.keys('*')).to eq ["test"]
        }
      end

      it 'delete_userで最後のユーザが削除されるとredisからroomが削除されることを確認する' do
        room = 'test'
        user1 = {name: 'testuser', num: 0}
        subscribe(room: room, name: user1[:name])
        expect do perform :delete_user, myName: 'testuser', nowName: 'testuser', nextNumber: user1[:num]
        end .to have_broadcasted_to('wikigame_channel_test').with{ |data|
          expect(data['message']['nextNumber']).to eq 0
          expect(data['message']['nextName']).to eq nil
          expect($redis.keys('*')).to eq []
        }
      end
    end
  end
end
