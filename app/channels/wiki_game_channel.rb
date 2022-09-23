module SubscriberTracker
  $redis = Redis.new(:host => 'localhost', :port => 6379)
  #add a subscriber to a Chat rooms channel 
  def self.add_sub(room, user_name)
    # count = sub_count(room)
    list = sub_get_list(room)
    # puts "list: #{list}"
    if list.nil?
      list = []
    end
    $redis.rpush(room, user_name)
  end

  def self.remove_sub(room, user_name)
    # puts "userNum: #{user_name}"
    count = sub_count(room)
    if count == 1
      $redis.del(room)
    else
      list = sub_get_list(room)
      # puts "sub_get_list: #{list}"
      del_room(room)
      list.delete(user_name)
      # puts "new_list: #{list}"
      $redis.rpush(room, list)
    end
  end

  def self.del_room(room)
    $redis.del(room)
  end

  def self.sub_get_list(room)
    $redis.lrange(room, 0, -1)
  end
  def self.sub_count(room)
    list = sub_get_list(room)
    # puts "count: #{list.size} #{list}"
    list.size
  end
end
require 'mechanize'
# TODO: 更新処理された時の処理
class WikiGameChannel < ApplicationCable::Channel
  # DONE: nextNumberは複数のコネクションがあっても大丈夫じゃない気がする
  # DONE: ActionCableで部屋ごとのconnectionの数を出す
  def subscribed
    if(SubscriberTracker.sub_count(params[:room]) >= 4)
      transmit({"action": "error", "error":"fillConnection", "message":"もうRoomがいっぱいです。"})
      return
    end
    # puts "params: #{params}"
    agent = Mechanize.new
    stream_from "wikigame_channel_#{params[:room]}"
    SubscriberTracker.add_sub(params[:room], params[:name])
    answerPage = agent.get("http://ja.wikipedia.org/wiki/Special:Randompage")
    answerHtml = answerPage.content.force_encoding("UTF-8")
    doc = Nokogiri::HTML.parse(answerHtml)
    title = doc.title
    # # puts "get", get_num_connection("wikigame_channel_#{params[:room]}")
    connect_number = SubscriberTracker.sub_count(params[:room])
    name_list = SubscriberTracker.sub_get_list(params[:room])
    data = {"action": "subscribed","answerTitle": title, "connectNumber":connect_number, "roomId": params[:room], 'nameList': name_list}
    ActionCable.server.broadcast("wikigame_channel_#{params[:room]}", data.as_json)
    # transmit({"answerTitle": title, "connectNumber":connect_number})
  end

  def start_game(data)
    agent = Mechanize.new
    startPage = agent.get("http://ja.wikipedia.org/wiki/Special:Randompage")
    html = startPage.content.force_encoding("UTF-8")
    # nextNumber = 1
    name_list = SubscriberTracker.sub_get_list(params[:room])
    data = {"action": "start_game", "data": html, 'nextNumber':0, 'nextName': name_list[0]}
    url = startPage.uri.to_s
    ActionCable.server.broadcast("wikigame_channel_#{params[:room]}", data.as_json)
  end

  # TODO: タイトル検索がエラーの時にそのことをフロント側に伝える
  def send_url(data)
    # stream_from 'wikigame_channel'
    # puts "test",data["myNumber"], data["nextNumber"]
    agent = Mechanize.new
    page = agent.get("https://ja.wikipedia.org/wiki/#{data["title"]}")
    html = page.content.force_encoding("UTF-8")
    # nextNumber = 1
    nextNumber = data["nextNumber"] + 1
    connect_number = SubscriberTracker.sub_count(params[:room])
    # puts "numberTrue: #{nextNumber >= connect_number}"
    if(nextNumber >= connect_number)
      nextNumber = 0
    end
    name_list = SubscriberTracker.sub_get_list(params[:room])
    data = {"action": "send_url","data": html, 'nextName': name_list[nextNumber], 'nextNumber': nextNumber}
    url = page.uri.to_s
    # transmit(data)
    ActionCable.server.broadcast("wikigame_channel_#{params[:room]}", data.as_json)
    # transmit(data)
  end

  def decied_winner(data)
    # stream_from 'wikigame_channel'
    winnerData = {
      action: 'decied_winner',
      winner: data["name"],
    }
    # transmit(data)
    SubscriberTracker.del_room(params[:room])
    ActionCable.server.broadcast("wikigame_channel_#{params[:room]}", winnerData.as_json)
    # transmit(data)
  end
  # Userを削除後、そのUserの順番だった場合は順番の変更を行う
  def delete_user(data)
    nextNumber = data["nextNumber"]
    # puts "test: #{data["myNumber"]} #{data["nextNumber"]} #{data["nowName"]} #{data["myName"]}"
    SubscriberTracker.remove_sub(params[:room], data["myName"])
    if data["myName"] === data["nowName"]
      connect_number = SubscriberTracker.sub_count(params[:room])
      # puts "connect_number: #{connect_number}"
      if(nextNumber >= connect_number)
        nextNumber = 0
      end
    end
    name_list = SubscriberTracker.sub_get_list(params[:room])
    nextName = name_list[nextNumber]
    data = {'action': 'delete_user','nextNumber': nextNumber, 'nextName': nextName, 'nameList': name_list}
    ActionCable.server.broadcast("wikigame_channel_#{params[:room]}", data.as_json)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    
  end
end
