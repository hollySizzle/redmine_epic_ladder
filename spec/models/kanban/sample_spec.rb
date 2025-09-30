# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Kanban Sample Test', type: :model do
  describe 'basic RSpec test' do
    it 'returns true' do
      expect(true).to be true
    end

    it 'calculates 1 + 1' do
      expect(1 + 1).to eq(2)
    end

    it 'checks string' do
      expect('Hello RSpec').to include('RSpec')
    end
  end

  describe 'Redmine integration' do
    it 'can access Issue model' do
      expect(defined?(Issue)).to be_truthy
    end

    it 'can access Project model' do
      expect(defined?(Project)).to be_truthy
    end

    it 'can access Tracker model' do
      expect(defined?(Tracker)).to be_truthy
    end
  end
end