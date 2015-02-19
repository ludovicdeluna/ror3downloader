class CreateFiles < ActiveRecord::Migration
  def change
    create_table :files do |t|
      t.string    :original_name
      t.string    :name
      t.datetime  :uploaded_at
      t.integer   :session_id
      t.integer   :size

      t.timestamps
    end
  end
end
