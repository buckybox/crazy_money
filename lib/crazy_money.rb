require "bigdecimal"
require "i18n"
require "currency_data"

class CrazyMoney
  include Comparable

  module Configuration
    class << self
      attr_accessor :current_currency
    end
  end

  def self.zero
    new 0
  end

  def initialize amount
    @amount = BigDecimal.new(amount.to_s)
  end

  def to_s(decimal_places: 2)
    if current_currency = Configuration.current_currency
      decimal_places = currency(current_currency).decimal_places
    end

    sprintf("%.#{decimal_places}f", @amount)
  end

  def inspect
    "#<CrazyMoney amount=#{to_s}>"
  end

  def == other
    @amount == BigDecimal.new(other.to_s)
  end
  alias_method :eql?, :==

  def <=> other
    @amount <=> BigDecimal.new(other.to_s)
  end

  def positive?
    @amount > 0
  end

  def negative?
    @amount < 0
  end

  def zero?
    @amount.zero?
  end

  def opposite
    self.class.new(self * -1)
  end

  def cents(ratio = 100)
    @amount * BigDecimal.new(ratio.to_s)
  end

  def + other; self.class.new(@amount + BigDecimal.new(other.to_s)); end
  def - other; self.class.new(@amount - BigDecimal.new(other.to_s)); end
  def / other; self.class.new(@amount / BigDecimal.new(other.to_s)); end
  def * other; self.class.new(@amount * BigDecimal.new(other.to_s)); end

  # FIXME: needs polishing
  def with_currency iso_code
    currency = currency(iso_code) || raise(ArgumentError, "Unknown currency: #{iso_code.inspect}")

    left, right = to_s(decimal_places: currency.decimal_places).split(".")
    decimal_mark = right.nil? ? "" : currency.decimal_mark
    sign = left.slice!("-")

    left = left.reverse.scan(/.{1,3}/).map(&:reverse).reverse. # split every 3 digits right-to-left
      join(thousands_separator)

    formatted = [sign, left, decimal_mark, right].join

    if currency.symbol_first
      [currency.prefered_symbol, formatted]
    else
      [formatted, " ", currency.prefered_symbol]
    end.join
  end

private

  def thousands_separator
    I18n.t("number.currency.format.thousands_separator", default: " ")
  end

  def currency iso_code
    ::CurrencyData.find(iso_code)
  end
end
