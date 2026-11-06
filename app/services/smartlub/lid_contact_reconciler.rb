# [custom] Fixes WhatsApp contacts created from a LID (Linked ID) instead of the phone number.
#
# Messages imported from history by Evolution API only carry the LID
# (e.g. 133766890709106@lid), which the integration stored as phone_number
# "+133766890709106". Live messages carry the real number, so a second contact
# gets created for the same customer. Evolution keeps the LID -> phone pairs on
# its Message table (key.remoteJid / key.remoteJidAlt); we read them and:
#   - merge the LID contact into the phone contact when both exist;
#   - otherwise turn the LID contact into the phone contact.
class Smartlub::LidContactReconciler
  MAPPING_SQL = <<~SQL.squish.freeze
    SELECT DISTINCT split_part(key->>'remoteJid', '@', 1) AS lid,
                    split_part(key->>'remoteJidAlt', '@', 1) AS phone
    FROM "Message"
    WHERE key->>'remoteJid' LIKE '%@lid'
      AND key->>'remoteJidAlt' LIKE '%@s.whatsapp.net'
  SQL

  def self.evolution_mappings(url = ENV.fetch('EVOLUTION_DATABASE_URL', nil))
    return [] if url.blank?

    conn = PG.connect(url)
    conn.exec(MAPPING_SQL).map { |row| [row['lid'], row['phone']] }
  ensure
    conn&.close
  end

  def initialize(mappings: self.class.evolution_mappings, dry_run: false)
    @mappings = mappings
    @dry_run = dry_run
  end

  # Returns a list of [action, lid_contact_id, phone_contact_id] for logging.
  def perform
    @mappings.flat_map { |lid, phone| reconcile(lid, phone) }
  end

  private

  def reconcile(lid, phone)
    return [] if lid.blank? || phone.blank? || lid == phone

    Contact.where(phone_number: "+#{lid}").filter_map do |lid_contact|
      phone_contact = lid_contact.account.contacts.find_by(phone_number: "+#{phone}")
      phone_contact ? merge(lid_contact, phone_contact) : convert(lid_contact, phone)
    end
  end

  def merge(lid_contact, phone_contact)
    unless @dry_run
      ContactMergeAction.new(account: phone_contact.account, base_contact: phone_contact, mergee_contact: lid_contact).perform
    end
    [:merged, lid_contact.id, phone_contact.id]
  end

  def convert(lid_contact, phone)
    unless @dry_run
      attrs = { phone_number: "+#{phone}", identifier: "#{phone}@s.whatsapp.net" }
      attrs[:name] = "+#{phone}" if lid_contact.name.to_s.gsub(/\D/, '') == lid_contact.phone_number.to_s.delete('+')
      attrs.delete(:identifier) if Contact.where(account_id: lid_contact.account_id, identifier: attrs[:identifier]).exists?
      lid_contact.update!(attrs)
    end
    [:converted, lid_contact.id, nil]
  end
end
