# frozen_string_literal: true

class CreateForceTagGroupOrderSetting < ActiveRecord::Migration[7.2]
  def up
    # Check if the setting exists to avoid duplicates
    unless execute("SELECT 1 FROM site_settings WHERE name = 'force_tag_group_order'").any?
      execute <<~SQL
        INSERT INTO site_settings (name, data_type, value, created_at, updated_at)
        VALUES ('force_tag_group_order', 1, '', NOW(), NOW())
      SQL
    end

    # Ensure force_tag_group_order_enabled exists
    unless execute("SELECT 1 FROM site_settings WHERE name = 'force_tag_group_order_enabled'").any?
      execute <<~SQL
        INSERT INTO site_settings (name, data_type, value, created_at, updated_at)
        VALUES ('force_tag_group_order_enabled', 7, 't', NOW(), NOW())
      SQL
    end
  end

  def down
    execute "DELETE FROM site_settings WHERE name IN ('force_tag_group_order', 'force_tag_group_order_enabled')"
  end
end
```

<xaiArtifact artifact_id="1322b504-2e00-41e8-8f31-e080a6cf4efa" artifact_version_id="14d8b511-fc0c-433d-a5dd-382dc61d56eb" title="app/controllers/admin_force_tag_group_order_controller.rb" contentType="text/ruby">
```ruby
# frozen_string_literal: true

module Admin
  class ForceTagGroupOrderController < AdminController
    requires_plugin 'force_tag_group_order'

    def index
      tag_groups = TagGroup.all.pluck(:name, :id).map { |name, id| { name: name, id: id } }
      selected_order = SiteSetting.get(:force_tag_group_order).to_s.split(',').map(&:strip).reject(&:empty?)
      render_json_dump(tag_groups: tag_groups, order: selected_order)
    end

    def update
      new_order = params[:order]
      if new_order.is_a?(Array) && new_order.all? { |name| name.is_a?(String) }
        SiteSetting.set_and_log('force_tag_group_order', new_order.join(','))
        render json: success_json
      else
        render json: failed_json, status: 400
      end
    end
  end
end
```

<xaiArtifact artifact_id="fe3cd5db-b932-44f5-a0c1-e82626769cf3" artifact_version_id="03194d55-ae4c-48e0-b8ac-57c61083be66" title="config/routes.rb" contentType="text/ruby">
# frozen_string_literal: true

Discourse::Application.routes.append do
  scope '/admin/plugins/force-tag-group-order', constraints: AdminConstraint.new do
    get '' => 'admin/force_tag_group_order#index'
    put '' => 'admin/force_tag_group_order#update'
  end
end
```

<xaiArtifact artifact_id="048939b5-0ef1-4987-bbf4-5cdccf069aaf" artifact_version_id="e1f0b5a6-abcd-4d81-8458-1571d5aae839" title="app/assets/javascripts/admin/addon/components/force-tag-group-order.js" contentType="text/javascript">
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

export default class ForceTagGroupOrder extends Component {
  @service ajax;
  @tracked tagGroups = [];
  @tracked selectedOrder = [];

  constructor() {
    super(...arguments);
    this.loadTagGroups();
  }

  async loadTagGroups() {
    try {
      const data = await this.ajax.request('/admin/plugins/force-tag-group-order');
      this.tagGroups = data.tag_groups;
      this.selectedOrder = data.order;
    } catch (e) {
      console.error('[force_tag_group_order] Error loading tag groups:', e);
    }
  }

  @action
  updateOrder(newOrder) {
    this.selectedOrder = newOrder;
    this.saveOrder();
  }

  @action
  addTagGroup(value) {
    if (value && !this.selectedOrder.includes(value)) {
      this.selectedOrder = [...this.selectedOrder, value];
      this.saveOrder();
    }
  }

  @action
  remove(groupName) {
    this.selectedOrder = this.selectedOrder.filter(name => name !== groupName);
    this.saveOrder();
  }

  async saveOrder() {
    try {
      await this.ajax.request('/admin/plugins/force-tag-group-order', {
        method: 'PUT',
        data: { order: this.selectedOrder }
      });
    } catch (e) {
      console.error('[force_tag_group_order] Error saving tag group order:', e);
    }
  }
}
```

<xaiArtifact artifact_id="7e4d30ae-69b2-4f5d-8023-9c5d98d56b48" artifact_version_id="7afd58e5-b1c6-43c1-a58d-b03b4f51532d" title="app/assets/javascripts/admin/addon/templates/components/force-tag-group-order.hbs" contentType="text/html">
<div class="force-tag-group-order">
  <h3>{{i18n "force_tag_group_order.title"}}</h3>
  <p>{{i18n "force_tag_group_order.description"}}</p>
  {{#if tagGroups.length}}
    <DndList
      @items={{this.selectedOrder}}
      @onChange={{this.updateOrder}}
      as |item|
    >
      <div class="tag-group-item">
        {{item}}
        <button {{on "click" (fn this.remove item)}} class="btn btn-danger btn-small">{{i18n "force_tag_group_order.remove"}}</button>
      </div>
    </DndList>
    <h4>{{i18n "force_tag_group_order.available_groups"}}</h4>
    <select onchange={{action "addTagGroup" value="target.value"}}>
      <option value="">{{i18n "force_tag_group_order.select_group"}}</option>
      {{#each tagGroups as |group|}}
        {{#unless (includes this.selectedOrder group.name)}}
          <option value={{group.name}}>{{group.name}}</option>
        {{/unless}}
      {{/each}}
    </select>
  {{else}}
    <p>{{i18n "force_tag_group_order.no_groups"}}</p>
  {{/if}}
</div>
```

<xaiArtifact artifact_id="159b5cef-f8d3-4149-8d0e-6ba9d15d04d1" artifact_version_id="37b58615-593b-4768-8a63-f5fbad280cce" title="config/locales/client.en.yml" contentType="text/yaml">
en:
  force_tag_group_order:
    title: "Force Tag Group Order"
    description: "Select the order in which tag groups should display on topics. Tags within prioritized groups appear first, followed by other tags alphabetically."
    select_group: "Select a tag group"
    remove: "Remove"
    available_groups: "Available Tag Groups"
    no_groups: "No tag groups found. Create tag groups in the admin panel first."
```

### Installation Steps
1. **Remove Existing Plugin**:
   - SSH into your server: `ssh root@talk`.
   - Remove the old plugin: `rm -rf /var/www/discourse/plugins/force-tag-group-order`.

2. **Create New Directory Structure**:
   - Navigate: `cd /var/www/discourse/plugins`.
   - Create directory: `mkdir force_tag_group_order && cd force_tag_group_order`.
   - Create subdirectories:
     ```bash
     mkdir -p db/migrate
     mkdir -p app/assets/javascripts/admin/addon/components
     mkdir -p app/assets/javascripts/admin/addon/templates/components
     mkdir -p app/controllers/admin
     mkdir -p config/locales
     ```
3. **Add Files**:
   - Create each file with the corresponding artifact contents (excluding `<xaiArtifact>` tags):
     - `plugin.rb`: `nano plugin.rb`
     - `db/migrate/202505290001_create_force_tag_group_order_setting.rb`: `nano db/migrate/202505290001_create_force_tag_group_order_setting.rb`
     - `app/controllers/admin/admin_force_tag_group_order_controller.rb`: `nano app/controllers/admin/admin_force_tag_group_order_controller.rb`
     - `config/routes.rb`: `nano config/routes.rb`
     - `app/assets/javascripts/admin/addon/components/force-tag-group-order.js`: `nano app/assets/javascripts/admin/addon/components/force-tag-group-order.js`
     - `app/assets/javascripts/admin/addon/templates/components/force-tag-group-order.hbs`: `nano app/assets/javascripts/admin/addon/templates/components/force-tag-group-order.hbs`
     - `config/locales/client.en.yml`: `nano config/locales/client.en.yml`
   - Save each file (`Ctrl+O`, `Ctrl+X`).

4. **Update app.yml**:
   - Edit `/var/discourse/containers/app.yml`:
     ```bash
     nano /var/discourse/containers/app.yml
     ```
   - Find the `hooks` section and update the plugin URL:
     ```yaml
     hooks:
       after_code:
         - exec:
             cd: $home/plugins
             cmd:
               - git clone https://github.com/discourse/docker_manager.git
               - git clone https://github.com/discourse/discourse-subscriptions.git
               - git clone https://github.com/discourse/discourse-follow.git
               - git clone https://github.com/discourse/discourse-solved.git
               - git clone https://github.com/communiteq/discourse-private-topics.git
               - git clone https://github.com/discourse/discourse-assign.git
               - git clone https://github.com/tknospdr/discourse-auto-remove-group.git
               - git clone https://github.com/discourse/discourse-topic-voting.git
               - git clone https://github.com/discourse/discourse-livestream.git
               - git clone https://github.com/discourse/discourse-calendar.git
               - git clone https://github.com/jannolii/discourse-topic-trade-buttons.git
               # Replace the next line
               - git clone https://github.com/tknospdr/force-tag-group-order.git force_tag_group_order
     ```
   - Save and exit.

5. **Fix Redis Bind Issue**:
   - Stop stale Redis processes:
     ```bash
     pkill -f redis-server
     ```
   - Verify: `netstat -tulnp | grep 6379` (should show no output).

6. **Rebuild App**:
   - Run: `cd /var/discourse && ./launcher rebuild app`.
   - Monitor logs: `tail -f /var/discourse/shared/standalone/log/rebuild.log`.
   - **Share**: Any rebuild errors or the last 50 lines if it fails.

7. **Enable Plugin**:
   - Go to `/admin/site_settings`.
   - Search for `force_tag_group_order_enabled` and check it.
   - If missing, check `/admin/plugins` to confirm the plugin is installed.

8. **Configure Tag Groups**:
   - Ensure tag groups exist:
     - Go to `/admin/tags`.
     - Create “Genus” (add tag “Theraphosa”) and “Species” (add tag “blondi”).
   - Set display order:
     - Go to `/admin/plugins/force-tag-group-order`.
     - Select “Genus”, then “Species” (order matters).
     - Save changes (should update `force_tag_group_order` to “Genus,Species”).

9. **Test**:
   - Create/edit topic 8:
     - Add tags: “Theraphosa” (Genus), “blondi” (Species), “urgent” (no group).
   - Check the topic list and topic page for: `["Theraphosa", "blondi", "urgent"]`.
   - Run in Browser Console (F12):
     ```javascript
     fetch('/t/8.json?include_tags=true')
       .then(res => res.json())
       .then(data => console.log('Server tags:', data.tags))
       .catch(err => console.error('Fetch error:', err));
     ```
   - **Expected Output**: `Server tags: ["Theraphosa", "blondi", "urgent"]`.
   - Check logs: `tail -n 100 /var/discourse/shared/standalone/log/var-log/production.log`.
   - Look for: `[force_tag_group_order] Topic 8: Ordered tags: ["Theraphosa", "blondi", "urgent"]`.
   - **Share**:
     - `fetch` output.
     - UI tag order.
     - `production.log` entries (search for `[force_tag_group_order]`).
     - Any errors.

### Troubleshooting
1. **Rebuild Fails**:
   - Share the full `rebuild.log` error or last 50 lines.
   - Check other plugins:
     - `discourse-topic-trade-buttons` has an invalid version list. Temporarily remove it:
       ```bash
       mv /var/www/discourse/plugins/discourse-topic-trade-buttons /var/www/discourse-topic-trade-buttons-backup
       ```
     - Update `app.yml` to remove its `git clone` line.
     - Rebuild.
   - Verify migration syntax:
     ```bash
     cat /var/www/discourse/plugins/force_tag_group_order/db/migrate/202505290001_create_force_tag_group_order_setting.rb
     ```

2. **Plugin Not Loaded**:
   - If `force_tag_group_order_enabled` is missing, verify:
     - `ls -R /var/www/discourse/plugins/force_tag_group_order/`.
     - Migration ran: `grep force_tag_group_order /var/discourse/shared/standalone/log/var-log/production.log`.
   - Rebuild with only this plugin:
     ```bash
     mv /var/www/discourse/plugins /var/www/discourse-plugins-backup
     mkdir /var/www/discourse/plugins
     cp -r /var/www/discourse-plugins-backup/force_tag_group_order /var/www/discourse/plugins/
     ```
     - Update `app.yml` to clone only `force_tag_group_order`.
     - Rebuild.

3. **HTTP Errors**:
   - If 400 errors for `/t/8.json`, run:
     ```javascript
     fetch('/t/8.json?include_tags=true')
       .then(res => res.text().then(text => ({ status: res.status, body: text })))
       .then(data => console.log('Response:', data));
     ```
   - Share the response body.
   - If 500 errors, share `production.log` stack trace (search for `[force_tag_group_order]`).

4. **Incorrect Tag Order**:
   - If not `["Theraphosa", "blondi", "urgent"]`, share:
     - `fetch('/t/8.json?include_tags=true')` output.
     - UI tag order.
     - DOM: `<div class="discourse-tags">` for topic 8 (F12).
     - Log: `[force_tag_group_order] Topic 8: Ordered tags: [...]`.

5. **Admin UI Issues**:
   - If the UI doesn’t load, check Console for errors (e.g., “[force_tag_group_order] Error loading tag groups”).
   - Verify tag groups: `/admin/tags`.
   - Share JavaScript errors.

6. **Docker Upgrade**:
   - Upgrade Docker to 24.0.7:
     ```bash
     apt-get update
     apt-get install -y docker.io
     systemctl restart docker
     ```
   - Verify: `docker --version`.

### Next Steps
1. **Install Updated Plugin**:
   - Remove the old plugin, set up the new structure, update `app.yml`, and rebuild.
2. **Fix Redis**:
   - Kill stale Redis processes and verify port 6379 is free.
3. **Share Rebuild Results**:
   - `rebuild.log` errors or last 50 lines.
   - Confirmation of successful rebuild.
4. **Test Tag Order**:
   - `fetch('/t/8.json?include_tags=true')` output.
   - UI tag order (e.g., “Displayed: Theraphosa, blondi, urgent”).
   - `production.log` entries.
   - DOM structure if order is wrong.
5. **Confirm Setup**:
   - `force_tag_group_order_enabled` is enabled.
   - `/admin/plugins` shows the plugin.
   - Tag groups “Genus” and “Species” exist.
   - Migration ran (check `site_settings` table).
6. **Share Errors**:
   - Any 500/400 errors or JavaScript issues.
