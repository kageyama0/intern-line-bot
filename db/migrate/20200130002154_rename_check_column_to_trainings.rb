class RenameCheckColumnToTrainings < ActiveRecord::Migration[5.2]
  def change
    rename_column :trainings, :check, :done
  end
end
