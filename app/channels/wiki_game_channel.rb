class WikiGameChannel < ApplicationCable::Channel
  nextNumber = 1
  def subscribed
    if(ActionCable.server.connections.length > 4)
      transmit({"error":"fillConnection", "message":"もうRoomがいっぱいです。"})
      return
    end
    agent = Mechanize.new
    stream_from "wikigame_channel_#{params[:room]}"
    answerPage = agent.get("http://ja.wikipedia.org/wiki/Special:Randompage")
    answerHtml = answerPage.content.force_encoding("UTF-8")
    doc = Nokogiri::HTML.parse(answerHtml)
    title = doc.title
    connect_number = ActionCable.server.connections.length
    data = {"answerTitle": title, "connectNumber":connect_number, "roomId": params[:room]}
    ActionCable.server.broadcast("wikigame_channel_#{params[:room]}", message: data.as_json)
    # transmit({"answerTitle": title, "connectNumber":connect_number})
  end

  def start_game(data)
    agent = Mechanize.new
    startPage = agent.get("http://ja.wikipedia.org/wiki/Special:Randompage")
    html = startPage.content.force_encoding("UTF-8")
    nextNumber = 1
    data = {"data": html, 'nextNumber':nextNumber}
    url = startPage.uri.to_s
    ActionCable.server.broadcast("wikigame_channel_#{params[:room]}", message: data.as_json)
  end

  def send_url(data)
    # stream_from 'wikigame_channel'
    puts "test",data["myNumber"]
    agent = Mechanize.new
    page = agent.get("https://ja.wikipedia.org/wiki/#{data["title"]}")
    html = page.content.force_encoding("UTF-8")
    # nextNumber = 1
    connect_number = ActionCable.server.connections.length
    if(data["myNumber"] >= connect_number)
      nextNumber = 1
    else
      nextNumber = data["myNumber"] + 1
    end
    data = {"data": html, 'nextNumber': nextNumber}
    url = page.uri.to_s
    # transmit(data)
    ActionCable.server.broadcast("wikigame_channel_#{params[:room]}", message: data.as_json)
    # transmit(data)
  end

  def decied_winner(data)
    # stream_from 'wikigame_channel'
    winnerData = {
      winner: data["name"],
    }
    data = {"data": winnerData}
    # transmit(data)
    ActionCable.server.broadcast("wikigame_channel_#{params[:room]}", message: data.as_json)
    # transmit(data)
  end
  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
