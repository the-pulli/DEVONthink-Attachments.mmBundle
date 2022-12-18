module DEVONthink
  # Rule for the files, that get added to DT
  class Rule
    # Modify this hash for your needs
    # The part after '_' of the hash key gets applied as method to the attachments array
    RULES = {
      filename_reject!: /signature|msg|encrypted|openpgp|smime\.p7s|asc/i,
      mime_reject!: /pgp-encrypted/i,
      mime_select!: /application/i
    }.freeze

    def initialize(attachments)
      @attachments = attachments
    end

    def apply
      RULES.each do |k, v|
        instr = k.to_s.split('_').map(&:to_sym).reverse
        @attachments.send(instr.first) { |a| a[instr.last].match?(v) }
      end
      @attachments
    end
  end
end
