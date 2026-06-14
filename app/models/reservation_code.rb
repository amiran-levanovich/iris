# frozen_string_literal: true

# Generates short, human-friendly reservation codes. The alphabet is uppercase
# and ambiguity-safe: it omits look-alike characters (I, L, O, 0, 1) so a code
# can be read aloud or typed without confusion.
module ReservationCode
  ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
  LENGTH = 6

  def self.generate(length = LENGTH)
    Array.new(length) { ALPHABET[SecureRandom.random_number(ALPHABET.length)] }.join
  end
end
