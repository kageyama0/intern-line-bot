class CreateTrainings < ActiveRecord::Migration[5.2]
  def change
    create_table :trainings do |t|
      t.string :menu
      t.boolean :check, default: false

      t.timestamps
    end
  end
end
