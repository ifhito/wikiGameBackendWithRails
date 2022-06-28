class CreateRooms < ActiveRecord::Migration[6.0]
  def change
    create_table :rooms do |t|
      t.string :room
      t.string :user1
      t.string :user2
      t.string :user3
      t.string :user4
      t.string :roomId

      t.timestamps
    end
  end
end
