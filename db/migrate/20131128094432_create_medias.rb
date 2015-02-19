class CreateMedias < ActiveRecord::Migration
  def change
    create_table :medias do |t|
      t.integer :user_id
      t.string :name
      t.string :original_name
      t.integer :size
      t.integer :session_id
      t.datetime :uploaded_at

      t.timestamps
    end
  end
end
