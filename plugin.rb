# name: display-tags-in-order
# about: Preserves the order of tags as they were added to a topic
# version: 0.1
# authors: David Muszynski
# url: https://github.com/your-repo/display-tags-in-order

enabled_site_setting :display_tags_in_order_enabled

after_initialize do
  add_to_serializer(:topic_view, :tags) do
    object.topic.tags.order('topic_tags.id').pluck(:name)
  end
  add_to_serializer(:basic_topic, :tags) do
    object.tags.order('topic_tags.id').pluck(:name)
  end
end
