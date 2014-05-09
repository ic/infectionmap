class AddFormFieldsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :gender, :string, null: true
    add_column :events, :age, :integer, null: true
    add_column :events, :event_subtype, :string, null: true
  end
end
