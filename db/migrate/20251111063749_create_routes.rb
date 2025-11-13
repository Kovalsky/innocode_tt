class CreateRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :routes do |t|
      t.string :title
      t.string :origin
      t.string :destination
      t.timestamp :last_updated_at
    end
  end
end
