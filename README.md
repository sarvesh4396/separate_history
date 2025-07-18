# SeparateHistory

[![CI](https://github.com/sarvesh4396/separate_history/actions/workflows/ci.yml/badge.svg)](https://github.com/sarvesh4396/separate_history/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/separate_history.svg)](https://badge.fury.io/rb/separate_history)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`SeparateHistory` provides a simple and flexible way to keep a complete history of your ActiveRecord model changes in a separate, dedicated history table. It automatically records every `create`, `update`, and `destroy` event, ensuring you have a full audit trail of your data.

## Features

- **Automatic History Tracking:** Automatically creates a history record for every create, update, and destroy action on your models.
- **Dedicated History Tables:** Keeps your history data separate from your primary tables, ensuring your main application's performance is not impacted.
- **Point-in-Time Recovery:** Easily retrieve the state of a record at any point in the past.
- **Easy Setup:** Get started with a single line in your model and a simple migration generator.
- **Flexible Configuration:** Select which attributes to track, customize history table names, and more.
- **Data Integrity:** Includes a `manipulated?` method to easily check if a history record has been altered after its creation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'separate_history'
```

And then execute:

```bash
$ bundle install
```

## Quick Start

Getting started with `SeparateHistory` is a three-step process:

### 1. Generate the History Table Migration

Use the provided generator to create a migration for the history table. For a model named `User`, run:

```bash
$ rails g separate_history:sync User
```

This creates a migration file that defines the schema for your history table.

### 2. Generate the History Model

Next, generate the history model file. This model will include the necessary `SeparateHistory::History` module.

```bash
$ rails g separate_history:model User
```

This creates the `app/models/user_history.rb` file.

### 3. Run the Migration and Add to Your Model

Run the migration to create the table in your database:

```bash
$ rails db:migrate
```

Finally, add the `has_separate_history` macro to your original model:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_separate_history
end
```

That's it! Now, every change to a `User` instance will be recorded in the `user_histories` table.
## Usage

### Basic Setup

1. Generate and run the migration for your model:

```bash
rails generate separate_history:migration User
rails db:migrate
```

2. Add to your model:

```ruby
class User < ApplicationRecord
  has_separate_history
end
```

### Tracking Options

#### Track Specific Attributes

```ruby
class Article < ApplicationRecord
  has_separate_history only: [:title, :content]
end
```

#### Exclude Specific Attributes

```ruby
class User < ApplicationRecord
  has_separate_history except: [:last_sign_in_ip, :encrypted_password]
end
```

#### Track Only Changed Attributes

```ruby
class User < ApplicationRecord
  has_separate_history track_changes: true
end
```

### Advanced Usage

#### Custom History Class Name

```ruby
class AdminUser < ApplicationRecord
  has_separate_history history_class_name: 'AdminActionLog'
end
```

#### Track Specific Events

Track only certain events (create/update/destroy):

```ruby
class Document < ApplicationRecord
  has_separate_history events: [:create, :update]  # Only track creation and updates
end
```

#### Accessing History

```ruby
# Get all history records for a user
user = User.find(1)
user.user_histories.each do |history|
  puts "Event: #{history.event} at #{history.history_created_at}"
end

# Or use the alias
user.separate_histories.each { |h| puts h.inspect }
```

#### Class-Level History Queries

```ruby
# Get historical state of a record at a specific time
old_user = User.history_as_of(user_id, 1.month.ago)

# Check if history exists for a record
if User.history_exists?(user_id)
  # Do something with history
end
```

### Point-in-Time History

You can retrieve the state of a record at any given point in time using the `history_for` class method. It returns the last history record created before or at the specified timestamp, giving you a precise snapshot of the record's state.

This query uses the `history_updated_at` timestamp to ensure accuracy, even if records were created out of order or their timestamps were manually altered.

```ruby
# Get the user record as it was 2 days ago
user_snapshot = User.history_for(user.id, 2.days.ago)
puts user_snapshot.name # => "Old Name"

# Get what a user looked like 1 week ago
user_week_ago = user.history_as_of(1.week.ago)

# Get the state of a record that might have been deleted
old_user = User.history_as_of(deleted_user_id, 1.month.ago)
```

### Error Handling

When the history table is missing, you'll get a helpful error message:

```
History table `user_histories` is missing. 
Run `rails g separate_history:model User` to create it.
```

### Validation and Options

SeparateHistory includes built-in validation for options:

```ruby
# These will raise ArgumentError:
has_separate_history only: [:name], except: [:email]  # Can't use both only and except
has_separate_history invalid_option: true             # Invalid option
has_separate_history events: [:invalid_event]         # Invalid event type
has_separate_history track_changes: 'yes'             # Must be boolean
```

## Instance Methods

When you include `has_separate_history` in your model, the following instance methods become available:

- **`#snapshot_history`**  
  Manually create a snapshot history record for the current state.

- **`#history?`**  
  Returns `true` if any history exists for this record, otherwise `false`.

- **`#history_as_of(timestamp)`**  
  Returns the state of the record at or before the given timestamp.

- **`#all_history`**  
  Returns all history records for this instance.

- **`#latest_history`**  
  Returns the most recent history record for this instance.

- **`#clear_history(force: true)`**  
  Deletes all history records for this instance.  
  **Warning:** You must pass `force: true` to confirm deletion.

**Example:**
```ruby
user = User.create!(name: "Alice")
user.update!(name: "Bob")
user.snapshot_history
user.history? # => true
user.all_history # => [<UserHistory ...>, ...]
user.latest_history # => <UserHistory ...>
user.history_as_of(1.day.ago) # => <UserHistory ...>
user.clear_history(force: true)
```

## Advanced Usage

### Tracking Only Changes

By default, `SeparateHistory` saves a complete snapshot of the record on every change. For high-traffic tables, this can lead to a lot of data storage. You can optimize this by enabling the `track_changes` option. When set to `true`, only the attributes that actually changed during an `update` event will be saved.

```ruby
# in app/models/user.rb
class User < ApplicationRecord
  has_separate_history track_changes: true
end
```

With this enabled, if you only update a user's name, the history record will store the new name, but all other attributes will be `nil`.

### Excluding Attributes

You can prevent certain attributes from being saved to the history table by using the `except` option. This is useful for ignoring fields that change frequently but aren't important for auditing, like `sign_in_count` or `last_login_at`.

```ruby
# Only track changes to name and email
class User < ApplicationRecord
  has_separate_history only: [:name, :email]
end

# Track all attributes except for sign_in_count
class User < ApplicationRecord
  has_separate_history except: [:sign_in_count]
end
```

### Custom History Class Name

If you want to use a different name for your history model, you can specify it with the `history_class_name` option.

```ruby
# in app/models/user.rb
class User < ApplicationRecord
  has_separate_history history_class_name: 'UserAuditTrail'
end

# in app/models/user_audit_trail.rb
class UserAuditTrail < ApplicationRecord
  # ...
end
```

### Checking for Manipulation

To verify that a history record has not been altered since it was first created, you can use the `manipulated?` method.

```ruby
last_history = user.histories.last
last_history.manipulated? # => false

# If someone changes the record later...
last_history.update(name: "A new name")
last_history.manipulated? # => true
```

## Creating Snapshots

If you add `SeparateHistory` to a model with existing records, you may want to create an initial history entry for them. You can do this by creating a `snapshot` event. This is also useful for creating periodic backups of your records.

Here is an example of a Rake task to create an initial snapshot for all records in your `User` model:

```ruby
# lib/tasks/history.rake
namespace :history do
  desc "Create initial history records for existing users"
  task sync_users: :environment do
    User.find_each do |user|
      history_class = User.history_class
      unless history_class.exists?(original_id: user.id)
        history_class.create!(user.attributes.merge(original_id: user.id, event: 'snapshot'))
        puts "Created snapshot for User ##{user.id}"
      end
    end
  end
end
```

Run it with `bundle exec rake history:sync_users`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the tests (RSpec, Minitest, and RuboCop).

This project uses `appraisal` to test against multiple versions of Rails. The test suites can be run with:

```bash
$ bundle exec appraisal rake
```

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Development

For a detailed log of the debugging and development process for the Rails 7 compatibility fixes, please see [DEV.md](DEV.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/sarvesh4396/separate_history](https://github.com/sarvesh4396/separate_history).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
