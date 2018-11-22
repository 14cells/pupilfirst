require 'rails_helper'

describe InstamojoController do
  include FounderSpecHelper

  let(:level_0) { create :level, :zero }
  let(:level_0_targets) { create :target_group, milestone: true, level: level_0 }
  let!(:screening_target) { create :target, :admissions_screening, target_group: level_0_targets }
  let!(:cofounder_addition_target) { create :target, :admissions_cofounder_addition, target_group: level_0_targets }
  let!(:fee_payment_target) { create :target, :admissions_fee_payment, target_group: level_0_targets }

  let(:founder) { create :founder }
  let(:startup) { create :startup, level: level_0 }

  let(:instamojo_payment_request_id) { SecureRandom.hex }
  let(:long_url) { Faker::Internet.url }
  let(:short_url) { Faker::Internet.url }

  let(:payment) do
    create :payment,
      startup: startup,
      founder: founder,
      amount: Startups::FeeAndCouponDataService.new(startup).emi,
      instamojo_payment_request_id: instamojo_payment_request_id,
      instamojo_payment_request_status: 'Pending',
      short_url: short_url,
      long_url: long_url,
      billing_start_at: Time.now,
      billing_end_at: 1.month.from_now
  end

  let(:payment_id) { SecureRandom.hex }

  before do
    startup.founders << founder
    complete_target founder, screening_target
    complete_target founder, cofounder_addition_target
  end

  describe 'GET redirect' do
    before do
      allow_any_instance_of(Instamojo).to receive(:payment_details).with(
        payment_request_id: instamojo_payment_request_id,
        payment_id: payment_id
      ).and_return(
        payment_request_status: 'Completed',
        payment_status: 'Credit',
        fees: '123.45'
      )
    end

    it 'redirects to founder dashboard with the stage param set' do
      get :redirect, params: { payment_request_id: payment.instamojo_payment_request_id, payment_id: payment_id }
      expect(response).to redirect_to(student_dashboard_path(from: 'instamojo_redirect'))
    end

    it 'updates payment and associated entries' do
      get :redirect, params: { payment_request_id: payment.instamojo_payment_request_id, payment_id: payment_id }

      expect(response).to redirect_to(student_dashboard_path(from: 'instamojo_redirect'))

      expect(payment.reload.instamojo_payment_id).to eq(payment_id)
      expect(payment.instamojo_payment_request_status).to eq('Completed')
      expect(payment.instamojo_payment_status).to eq('Credit')
      expect(payment.fees).to eq(123.45)

      # payment target should now be marked complete
      founder = payment.founder
      fee_payment_status = Targets::StatusService.new(fee_payment_target, founder).status
      expect(fee_payment_status).to eq(Target::STATUS_COMPLETE)
    end

    context 'when a payment has already been marked paid' do
      let(:paid_at) { 5.seconds.ago.round }

      before do
        payment.update!(paid_at: paid_at, payment_type: Payment::TYPE_NORMAL)
      end

      it 'proceeds without updating paid_at' do
        get :redirect, params: { payment_request_id: payment.instamojo_payment_request_id, payment_id: payment_id }
        expect(response).to redirect_to(student_dashboard_path(from: 'instamojo_redirect'))
        expect(payment.reload.paid_at).to eq(paid_at)
      end
    end
  end

  describe 'POST webhook' do
    it 'updates payment and associated entries' do
      data = "43.21|#{payment_id}|#{payment.instamojo_payment_request_id}|Credit"
      digest = OpenSSL::Digest.new('sha1')
      computed_mac = OpenSSL::HMAC.hexdigest(digest, 'TEST_SALT', data)

      post :webhook, params: {
        payment_request_id: payment.instamojo_payment_request_id,
        payment_id: payment_id,
        status: 'Credit',
        fees: '43.21',
        mac: computed_mac
      }

      payment.reload

      expect(payment.instamojo_payment_id).to eq(payment_id)
      expect(payment.instamojo_payment_request_status).to eq('Completed')
      expect(payment.instamojo_payment_status).to eq('Credit')
      expect(payment.fees).to eq(43.21)

      # payment target should now be marked complete
      founder = payment.founder
      fee_payment_status = Targets::StatusService.new(fee_payment_target, founder).status
      expect(fee_payment_status).to eq(Target::STATUS_COMPLETE)
    end

    context 'when mac is incorrect or missing' do
      it 'returns 401 Unauthorized' do
        post :webhook, params: {
          payment_request_id: payment.instamojo_payment_request_id,
          payment_id: payment_id,
          status: 'Credit',
          fees: '43.21'
        }

        expect(response.status).to eq(401)
      end
    end

    context 'when the payment has failed' do
      it 'updates payment without marking it paid' do
        data = "43.21|#{payment_id}|#{payment.instamojo_payment_request_id}|Failed"
        digest = OpenSSL::Digest.new('sha1')
        computed_mac = OpenSSL::HMAC.hexdigest(digest, 'TEST_SALT', data)

        post :webhook, params: {
          payment_request_id: payment.instamojo_payment_request_id,
          payment_id: payment_id,
          status: 'Failed',
          fees: '43.21',
          mac: computed_mac
        }

        payment.reload

        expect(payment.instamojo_payment_id).to eq(payment_id)
        expect(payment.instamojo_payment_request_status).to eq('Pending')
        expect(payment.instamojo_payment_status).to eq('Failed')
        expect(payment.fees).to eq(43.21)

        # payment target should now be marked complete
        founder = payment.founder
        fee_payment_status = Targets::StatusService.new(fee_payment_target, founder).status
        expect(fee_payment_status).to eq(Target::STATUS_PENDING)
      end
    end
  end
end
