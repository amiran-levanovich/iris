module ApplicationHelper
  # Translated label for an enum value, e.g. human_enum(room, :status) or
  # human_enum(room, :status, "cleaning") for a value other than the current one.
  # Looks up activerecord.attributes.<model>.<enum_plural>.<value>.
  def human_enum(record, enum_name, value = record.public_send(enum_name))
    record.class.human_attribute_name("#{enum_name.to_s.pluralize}.#{value}")
  end

  # Safe "back" target for a page reachable from several lists (e.g. a guest
  # linked from the guests index, reservation rows, or the housekeeping board):
  # return to the referring page when it is same-origin, otherwise the fallback.
  def safe_back_path(fallback)
    referer = request.referer
    return fallback if referer.blank?

    uri = URI.parse(referer)
    uri.host == request.host && uri.port == request.port ? uri.request_uri : fallback
  rescue URI::InvalidURIError
    fallback
  end

  # Coloured pill for a reservation's lifecycle state. The status column is an
  # AASM state, not a Rails enum, but human_enum resolves it the same way.
  def reservation_status_tag(reservation)
    tag.span(human_enum(reservation, :status),
             class: "status status-#{reservation.status}")
  end

  # Form label marked with a required asterisk, e.g. required_label(form, :email).
  def required_label(form, attribute)
    form.label(attribute) do
      safe_join([
        form.object.class.human_attribute_name(attribute),
        " ",
        tag.abbr("*", class: "required", title: t("forms.required"))
      ])
    end
  end

  # [alpha2, name, dial] for every country, sorted by name. Used by the country
  # picker and the phone dial-code picker.
  def country_list
    @country_list ||= ISO3166::Country.all
                                      .map { |c| [ c.alpha2, c.iso_short_name, c.country_code ] }
                                      .sort_by { |_code, name, _dial| name }
  end

  # Countries that have an international dialing code, for the phone picker.
  def dialing_country_list
    country_list.select { |_code, _name, dial| dial.present? }
                .sort_by { |_code, name, _dial| name }
  end

  def country_name(alpha2)
    ISO3166::Country[alpha2]&.iso_short_name
  end

  def country_dial_code(alpha2)
    ISO3166::Country[alpha2]&.country_code
  end

  # Small flag image served from flagcdn (no asset vendoring). alpha2 comes from
  # our own country list, never user input.
  def country_flag_tag(alpha2)
    code = alpha2.to_s.downcase
    image_tag("https://flagcdn.com/20x15/#{code}.png",
              srcset: "https://flagcdn.com/40x30/#{code}.png 2x",
              width: 20, height: 15, alt: "", loading: "lazy", class: "flag")
  end

  # Label for a room in the booking dropdown: "101 — Double (€120.00)".
  def room_option_label(room)
    rate = number_to_currency(room.nightly_rate_cents / 100.0)
    "#{room.number} — #{human_enum(room, :room_type)} (#{rate})"
  end
end
