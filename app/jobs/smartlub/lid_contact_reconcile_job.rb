# [custom] See Smartlub::LidContactReconciler.
class Smartlub::LidContactReconcileJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return if ENV['EVOLUTION_DATABASE_URL'].blank?

    results = Smartlub::LidContactReconciler.new.perform
    Rails.logger.info("[Smartlub::LidContactReconcileJob] #{results.inspect}") if results.any?
  end
end
