class ConvertGuestCountryToCode < ActiveRecord::Migration[8.1]
  # Guest#country switched from a free-text name to an ISO-3166 alpha-2 code when
  # the country picker landed. Convert any existing names ("Germany" -> "DE").
  class MigrationGuest < ActiveRecord::Base
    self.table_name = "guests"
  end

  def up
    MigrationGuest.where.not(country: [ nil, "" ]).find_each do |guest|
      next if ISO3166::Country[guest.country] # already a valid alpha-2 code

      code = ISO3166::Country.find_country_by_any_name(guest.country)&.alpha2
      guest.update_columns(country: code) if code
    end
  end

  def down
    MigrationGuest.where.not(country: [ nil, "" ]).find_each do |guest|
      country = ISO3166::Country[guest.country]
      guest.update_columns(country: country.iso_short_name) if country
    end
  end
end
