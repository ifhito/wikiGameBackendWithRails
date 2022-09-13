require 'rails_helper'

RSpec.describe WikiGameChannel, type: :channel do

  # before do
  #   @chat_group = create(:chat_group)
  #   stub_connection 
  # end

  describe "メッセージの送信" do
    # before do
    #   @message = build(:message, chat_group_id: @chat_group.id)
    # end

    context "送信成功" do
      it "グループが選択されている状態でメッセージを送信するとメッセージがひとつDBに保存される" do
        subscribe(room: "test", name: "Ayumu")
        expect(subscription).to be_confirmed
        subscription
      end
    end
  end
end
