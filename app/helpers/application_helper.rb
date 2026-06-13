module ApplicationHelper
  # Translated label for an enum value, e.g. human_enum(room, :status) or
  # human_enum(room, :status, "cleaning") for a value other than the current one.
  # Looks up activerecord.attributes.<model>.<enum_plural>.<value>.
  def human_enum(record, enum_name, value = record.public_send(enum_name))
    record.class.human_attribute_name("#{enum_name.to_s.pluralize}.#{value}")
  end

  # Coloured pill for a reservation's lifecycle state. The status column is an
  # AASM state, not a Rails enum, but human_enum resolves it the same way.
  def reservation_status_tag(reservation)
    tag.span(human_enum(reservation, :status),
             class: "status status-#{reservation.status}")
  end

  # Label for a room in the booking dropdown: "101 — Double (€120.00)".
  def room_option_label(room)
    rate = number_to_currency(room.nightly_rate_cents / 100.0)
    "#{room.number} — #{human_enum(room, :room_type)} (#{rate})"
  end
end
