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
      this.selectedOrder = data.selected_order;
    } catch (e) {
      console.error('[force-tag-group-order] Error loading tag groups:', e);
    }
  }

  @action
  updateOrder(newOrder) {
    this.selectedOrder = newOrder;
    this.saveOrder();
  }

  async saveOrder() {
    try {
      await this.ajax.request('/admin/plugins/force-tag-group-order', {
        method: 'PUT',
        data: { order: this.selectedOrder }
      });
    } catch (e) {
      console.error('[force-tag-group-order] Error saving tag group order:', e);
    }
  }
}
