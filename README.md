Fog Tracker
================
Uses the Fog gem to track the state of cloud computing resources across multiple accounts, with multiple service providers.

  *BETA VERSION - needs functional testing with more cloud computing providers*


----------------
What is it?
----------------
The Fog Tracker uses the [Fog gem](https://github.com/fog/fog) to periodically poll one or more cloud computing accounts, and determines the state of their associated cloud computing "Resources": compute instances, disk volumes, stored objects, and so on. The most recent state of all Resources is saved in memory (as Fog objects), and can be accessed repeatedly with no network overhead, using a simple, Regular-Expression-based query.


----------------
Why is it?
----------------
The Fog Tracker is intended to be a foundation library, on top of which more complex cloud dashboard or management applications can be built. It allows such applications to decouple their requests to cloud service providers from their access to the results of those requests.


----------------
Where is it? (Installation)
----------------
Install the Fog Tracker gem (and its dependencies if necessary) from RubyGems

    gem install fog_tracker [rake bundler]


----------------
How is it [done]? (Usage)
----------------
1) Require the gem, and create a `FogTracker::Tracker`. Pass it some account information in a hash, perhaps loaded from a YAML file:

    require 'fog_tracker'
    tracker = FogTracker::Tracker.new(YAML::load(File.read 'accounts.yml'))

  Here are the contents of a sample `accounts.yml`:

    AWS EC2 development account:
      :provider: AWS
      :service: Compute
      :credentials:
        :aws_access_key_id: XXXXXXXXXXXXXXXXXXXX
        :aws_secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      :polling_time: 180
	  :exclude_resources:
	  - :flavors
	  - :images
    Rackspace development account:
      :provider: Rackspace
      :service: Compute
      :credentials:
        :rackspace_api_key: XXXXXXXXXXXXXXXXXXXX
        :rackspace_username: XXXXXXXXX
      :polling_time: 180

2) Call `start` on the Tracker. It will run asynchronously, with one thread per account. At any time, you can call `start` or `stop` on it, and query the resulting collections of Fog Resource objects.

    tracker.start

3) Access the Fog object collections by calling `Tracker::query`, and passing it a filter-based query String. The query string format is: `account_name::service::provider::collection`

    # get all Compute instances across all accounts and providers
    tracker.query("*::Compute::*::servers")

    # get all Amazon EC2 Resources, of all types, across all accounts
    tracker["*::Compute::AWS::*"]	# the [] operator is the same as query()

    # get all S3 objects in a given account
    tracker["my production account::Storage::AWS::files"]

  If you're tired of calling `each` on the results of every query, pass a single-argument block, and it will be invoked once with each resulting resource:

    tracker.query("*::*::*::*"){|r| puts "Found #{r.class} #{r.identity}"}

  You can also pass a Proc to the Tracker at initialization, which will be invoked whenever an account's Resources have been updated. It should accept a list of the updated Resources as its first argument:

    FogTracker::Tracker.new(YAML::load(File.read 'accounts.yml'),
      :callback => Proc.new do |resources|
      	puts "Got #{resources.count} resources from account "+
		      resources.first.tracker_account[:name]
      end
    ).start

  The appropriate account information for each Fog resource, read from `accounts.yml` can be obtained by calling its `tracker_account` method.


----------------
Who is it? (Contribution)
----------------
This Gem was created by Benton Roberts _(benton@bentonroberts.com)_, but draws heavily on the work of the [Fog project](http://fog.io/). Thanks to geemus, and to all Fog contributors.

The project is still in its early stages, and needs to be tested with many more of Fog's cloud providers. Helping hands are appreciated!

1) Install project dependencies.

    gem install rake bundler

2) Fetch the project code and bundle up...

    git clone https://github.com/benton/fog_tracker.git
    cd fog_tracker
    bundle

3) Run the tests:

    rake
