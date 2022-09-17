require 'rails_helper'

RSpec.describe WikiGameChannel, type: :channel do

  # before do
  #   @chat_group = create(:chat_group)
  #   stub_connection 
  # end

  describe "メッセージの送信" do

    context "送信成功" do
      subject do
        # `subscribe`ヘルパーは、記載されているチャンネルへ
        # のサブスクライブアクションを実行する
        subscribe(room: "test", name: "Ayumu")
        # `subscription`はサブスクライブされたチャネルのインスタンス
        subscription
      end
      it "部屋にユーザが追加されると、redisに部屋とユーザが追加される" do
        subscribe(room: "test", name: "Ayumu")
        expect($redis.lrange("test", 0, -1)).to eq ["Ayumu"]
        expect($redis.keys('*')).to eq ["test"]
      end

      it "部屋が作成されるとそのユーザの答えのタイトル、接続の数、部屋のID, 参加者名がブロードキャストされる" do
        expect{subject}.to have_broadcasted_to("wikigame_channel_test").with{ |data|
          expect(data['message']['connectNumber']).to eq 0
          expect(data['message']['answerTitle']).to_not eq ''
          expect(data['message']['roomId']).to_not eq ''
        }
      end
      # {"data": html, 'nextNumber':0, 'nextName': name_list[0]}
      it "ゲームがスタートするとシードのHTML、現在の参加者の数、name_listの初めの名前が次のユーザとして追加される" do
      end

      it "send_urlが呼ばれた場合、渡されたURLのHTMLと次の名前、次の数字が渡される" do
      end

      it "decied_winnerが決まると勝利者の名前が渡される" do
      end

      it "delete_userが呼ばれると、渡されたデータのユーザがredisから削除され、次の順番のユーザの番号がフロントに渡される。" do
      end

      it "delete_userで最後のユーザが削除されるとredisからroomが削除されることを確認する" do
      end
    end
  end
end
