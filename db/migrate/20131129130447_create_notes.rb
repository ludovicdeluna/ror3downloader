class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.integer :media_id
      t.text :description

      t.timestamps
    end
  end
end
