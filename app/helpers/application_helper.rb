module ApplicationHelper
  # Translated label for an enum value, e.g. human_enum(room, :status) or
  # human_enum(room, :status, "cleaning") for a value other than the current one.
  # Looks up activerecord.attributes.<model>.<enum_plural>.<value>.
  def human_enum(record, enum_name, value = record.public_send(enum_name))
    record.class.human_attribute_name("#{enum_name.to_s.pluralize}.#{value}")
  end
end
