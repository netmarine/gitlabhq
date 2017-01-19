class ConvertApplicationSettingsRepositorySizeLimitToBytes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    connection.transaction do
      rename_column :application_settings, :repository_size_limit, :repository_size_limit_mb
      add_column :application_settings, :repository_size_limit, :integer, default: 0, limit: 8
    end

    bigint_expression = if Gitlab::Database.postgresql?
                          'repository_size_limit_mb::bigint * 1024 * 1024'
                        else
                          'repository_size_limit_mb * 1024 * 1024'
                        end

    connection.transaction do
      update_column_in_batches(:application_settings, :repository_size_limit, Arel::Nodes::SqlLiteral.new(bigint_expression)) do |t, query|
        query.where(t[:repository_size_limit_mb].not_eq(nil))
      end

      remove_column :application_settings, :repository_size_limit_mb
    end
  end

  def down
    connection.transaction do
      rename_column :application_settings, :repository_size_limit, :repository_size_limit_bytes
      add_column :application_settings, :repository_size_limit, :integer, default: 0, limit: nil
    end

    connection.transaction do
      update_column_in_batches(:application_settings, :repository_size_limit, Arel::Nodes::SqlLiteral.new('repository_size_limit_bytes / 1024 / 1024')) do |t, query|
        query.where(t[:repository_size_limit_bytes].not_eq(nil))
      end

      remove_column :application_settings, :repository_size_limit_bytes
    end
  end
end
