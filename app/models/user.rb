class User < ApplicationRecord
    has_secure_password

    validates_presence_of :email
    validates_uniqueness_of :email, case_sensitive: false
    validates_format_of :email, with: /@/
  
    before_save :downcase_email
    before_create :generate_confirmation_instructions

    # destroy the user in the members list if the user is deleted
    has_many :members, :dependent => :destroy

    # has many through members join table
    has_many :groups, :through => :members

    
    def downcase_email
      self.email = self.email.delete(' ').downcase
    end
  
    def generate_confirmation_instructions
      self.confirmation_token = generate_token
      self.confirmation_sent_at = Time.now.utc
    end
  
    def confirmation_token_valid?
      (self.confirmation_sent_at + 30.days) > Time.now.utc
    end
  
    def mark_as_confirmed!
      self.confirmation_token = nil
      self.confirmed_at = Time.now.utc
      save!
    end
  
    def generate_password_token!
      self.reset_password_token = generate_token
      self.reset_password_sent_at = Time.now.utc
      save!
    end
  
    def password_token_valid?
      (self.reset_password_sent_at + 24.hours) > Time.now.utc
    end
  
    def reset_password!(password)
      self.reset_password_token = nil
      self.password = password
      save
    end
  
    def update_new_email!(email)
      self.unconfirmed_email = email
      self.generate_confirmation_instructions
      save
    end
  
    def self.email_used?(email)
      existing_user = find_by("email = ?", email)
  
      if existing_user.present?
        return true
      else
        waiting_for_confirmation = find_by("unconfirmed_email = ?", email)
        return waiting_for_confirmation.present? && waiting_for_confirmation.confirmation_token_valid?
      end
    end
  
    def update_new_email!
      self.email = self.unconfirmed_email
      self.unconfirmed_email = nil
      self.mark_as_confirmed!
    end
  
    private
  
    def generate_token
      SecureRandom.hex(10)
    end
  
  end
  