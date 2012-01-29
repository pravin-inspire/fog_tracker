require 'spec_helper'

module FogTracker

    describe AccountTracker do

      before(:each) do
        @account_receiver = double "account callback object"
        @account_receiver.stub(:callback)
        @error_receiver = double "error callback object"
        @error_receiver.stub(:callback)
        @tracker = AccountTracker.new(
          FAKE_ACCOUNT_NAME, FAKE_ACCOUNT, #:logger => LOG, # uncomment to debug
          :callback => Proc.new do |resources|
              @account_receiver.callback(resources)
          end,
          :error_callback => Proc.new do |exception|
              @error_receiver.callback(exception)
          end
        )
      end

      it "exposes its Hash of account information" do
        @tracker.connection.should_not == nil
      end
      it "exposes the account name" do
        @tracker.name.should == FAKE_ACCOUNT_NAME
      end
      it "exposes the connection to its Fog service" do
        @tracker.account.should == FAKE_ACCOUNT
      end
      it "exposes the connection to its logger" do
        @tracker.log.should_not == nil
      end

      context "when it encounters an Exception while updating" do
        context "when initialized with an error callback" do
          it "should fire the callback" do
            CollectionTracker.any_instance.stub(:update).and_raise
            @error_receiver.should_receive(:callback).exactly(:once)
            @tracker.start
            sleep THREAD_STARTUP_DELAY
          end
        end
      end

      describe '#start' do
        it "sends update() to its CollectionTrackers" do
          update_catcher = double "mock for catching CollectionTracker::update"
          update_catcher.stub(:update)
          CollectionTracker.any_instance.stub(:update) do
            update_catcher.update
          end
          update_catcher.should_receive(:update)
          @tracker.start
          sleep THREAD_STARTUP_DELAY # wait for background thread to start
        end
        it "invokes its callback Proc when its account is updated" do
          @account_receiver.should_receive(:callback).
            exactly(FAKE_ACCOUNTS.size).times
          @tracker.start
          sleep THREAD_STARTUP_DELAY
        end
      end

      describe '#stop' do
        it "sets running? to false" do
          @tracker.start ; @tracker.stop
          @tracker.running?.should be_false
        end
        it "kills its timer thread" do
          @tracker.start ; @tracker.stop
          @account_receiver.should_not_receive(:callback)
          sleep THREAD_STARTUP_DELAY # wait to make sure no update()s are sent
        end
      end

      describe '#running?' do
        it "returns true if the AccountTracker is running" do
          @tracker.start
          @tracker.running?.should be_true
        end
        it "returns false if the AccountTracker is stopped" do
          @tracker.running?.should be_false
        end
      end

      describe '#tracked_types' do
        it "returns a list of Resource types tracked for its account" do
          @tracker.tracked_types.size.should be > 0
          @tracker.tracked_types.first.should be_an_instance_of String
        end
      end

      describe '#all_resources' do
        it "returns a flattened Array of all its CollectionTrackers collections" do
          COLLECTION = [ 1, 2, 3 ]
          NUM_TYPES = @tracker.tracked_types.size
          CollectionTracker.any_instance.stub(:collection).and_return(COLLECTION)
          @tracker.all_resources.should == ((1..NUM_TYPES).map {COLLECTION}).flatten
        end
      end

    end
end
