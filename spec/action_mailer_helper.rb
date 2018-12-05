# frozen_string_literal: true

require 'action_mailer'

class MailerOtherKlass; end

class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
end

# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def self.trigger(arg); end

  def email1
    self.class.trigger('hello')
  end

  def email2(arg)
    self.class.trigger(arg)
  end
end
