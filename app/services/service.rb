class Service

  # Singleton
  @instance = new
  private_class_method :new

  def self.instance
      @instance
    end

  def round_btc(not_rounded_btc_value)
      # min value : 0.00000001
      return ((not_rounded_btc_value*100000000).round.to_f)/100000000
  end

  def round_eur(not_rounded_eur_value)
    # min value : 0.01
    return ((not_rounded_eur_value*100).round.to_f)/100
end

end