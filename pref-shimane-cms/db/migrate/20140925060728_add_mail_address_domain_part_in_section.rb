class AddMailAddressDomainPartInSection < ActiveRecord::Migration
  def change
    add_column :sections, :domain_part, :string
  end
end
