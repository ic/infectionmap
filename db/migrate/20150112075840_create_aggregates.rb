class CreateAggregates < ActiveRecord::Migration
  def change
    create_table :aggregates do |t|
      t.string :disease
      t.float :latitude
      t.float :longitude
      t.float :weight

      t.timestamps null: false
    end
  end
end
