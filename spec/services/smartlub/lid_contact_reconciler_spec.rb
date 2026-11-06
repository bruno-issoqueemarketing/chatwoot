require 'rails_helper'

describe Smartlub::LidContactReconciler do
  let(:account) { create(:account) }
  let!(:lid_contact) { create(:contact, account: account, name: '133766890709106', phone_number: '+133766890709106') }

  it 'merges the LID contact into the existing phone contact' do
    phone_contact = create(:contact, account: account, name: 'Julio', phone_number: '+5516991179871')
    result = described_class.new(mappings: [%w[133766890709106 5516991179871]]).perform

    expect(result).to eq([[:merged, lid_contact.id, phone_contact.id]])
    expect(Contact.exists?(lid_contact.id)).to be(false)
  end

  it 'converts the LID contact when no phone contact exists' do
    described_class.new(mappings: [%w[133766890709106 5516991179871]]).perform

    expect(lid_contact.reload.phone_number).to eq('+5516991179871')
    expect(lid_contact.identifier).to eq('5516991179871@s.whatsapp.net')
    expect(lid_contact.name).to eq('+5516991179871')
  end

  it 'does not change anything on dry run' do
    described_class.new(mappings: [%w[133766890709106 5516991179871]], dry_run: true).perform

    expect(lid_contact.reload.phone_number).to eq('+133766890709106')
  end
end
