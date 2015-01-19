class CreateAggregates < ActiveRecord::Migration
  def change
    create_table :aggregates do |t|
      t.string :disease
      t.string:latitude
      t.string :longitude
      t.float :weight

      t.timestamps null: false
    end
  end
end
