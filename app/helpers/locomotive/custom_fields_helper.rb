module Locomotive
  module CustomFieldsHelper

    # Render all the form inputs based on the fields of a content type.
    #
    # @param [ Object ] content_type The content type the fields belong to
    # @param [ Object ] form The SimpleForm form instance
    #
    # @return [ String ] The form inputs
    #
    def render_custom_fields(content_type, form)
      html = content_type.ordered_entries_custom_fields.map do |field|
        render_custom_field(field, form)
      end

      html.join("\n").html_safe
    end

    # Render the form input based on the type of the field.
    #
    # @param [ Object ] field The field part of the content type
    # @param [ Object ] form The SimpleForm form instance
    #
    # @return [ String ] The form input
    #
    def render_custom_field(field, form)
      highlighted     = field._id == field._parent.label_field_id
      default_options = default_custom_field_options(field, form, highlighted)
      field_options   = custom_field_options(field, form)

      return '' if field_options.nil?

      options = default_options.merge(field_options)

      form.input options.delete(:name), options
    end

    def custom_field_options(field, form)
      method = "#{field.type}_custom_field_options"

      begin
        send(method, field, form.object)
      rescue NoMethodError
        nil
      end
    end

    def default_custom_field_options(field, form, highlighted)
      {
        name:   field.name,
        label:  label_for_custom_field(form.object, field),
        hint:   field.hint,
        wrapper_html: {
          class: "#{'highlighted' if highlighted}"
        }
      }
    end

    def belongs_to_custom_field_options(field, entry)
      slug      = field.class_name_to_content_type.slug
      target_id = entry.send(:"#{field.name}_id")

      {
        as:       :document_picker,
        edit:     {
          label:  custom_field_t(:edit, field.type),
          url:    target_id ? edit_content_entry_path(slug, target_id, _location: false) : nil
        },
        picker:   {
          label_method: :_label,
          list_url:     content_entries_path(slug, format: :json),
          placeholder:  custom_field_t(:placeholder, field.type, name: field.label.downcase),
          searching:    custom_field_t(:searching, field.type),
          no_matches:   custom_field_t(:no_matches, field.type),
          too_short:    custom_field_t(:too_short, field.type)
        }
      }
    end

    def boolean_custom_field_options(field, entry)
      { as: :toggle }
    end

    def date_custom_field_options(field, entry)
      _date_custom_field_options(field, 'calendar', 'date', date_moment_format)
    end

    def date_time_custom_field_options(field, entry)
      _date_custom_field_options(field, 'clock-o', 'date-time', datetime_moment_format)
    end

    def _date_custom_field_options(field, icon, css, format)
      {
        name:         :"formatted_#{field.name}",
        append:       icon_tag("fa-#{icon}"),
        wrapper_html: { class: css },
        input_html:   {
          data:       { format: format },
          maxlength:  10
        }
      }
    end

    def email_custom_field_options(field, entry)
      { as: :email }
    end

    def file_custom_field_options(field, entry)
      { as: :file }
    end

    def float_custom_field_options(field, entry)
      { as: :float, step: 0.1 }
    end

    def has_many_custom_field_options(field, entry)
      return nil if entry.new_record? || !field.ui_enabled?

      slug = field.class_name_to_content_type.slug

      {
        as:           :array,
        template:     {
          path:   'locomotive/custom_fields/types/has_many_entry',
          locals: { field: field, slug: slug }
        },
        wrapper_html: { class: 'has_many' },
        new_item: {
          label:  custom_field_t(:new_label, field.type),
          url:    new_content_entry_path(slug, {
            "content_entry[#{field.inverse_of}_id]" => entry._id,
            _location: false
          })
        }
      }
    end

    def integer_custom_field_options(field, entry)
      { as: :integer }
    end

    def select_custom_field_options(field, entry)
      {
        name:         "#{field.name}_id",
        as:           :editable_select,
        collection:   field.ordered_select_options.map { |option| [option.name, option.id] },
        manage_collection:    {
          label:  custom_field_t(:edit, field.type),
          url:    edit_custom_fields_select_options_path(entry.content_type.slug, field.name)
        }
      }
    end

    def string_custom_field_options(field, entry)
      { as: :string }
    end

    def tags_custom_field_options(field, entry)
      { wrapper_html: { class: 'tags' } }
    end

    def text_custom_field_options(field, entry)
      { as: field.text_formatting ? :rte : :text }
    end

    def custom_field_t(name, type, interpolation = {})
      t(name, { scope: ['locomotive.custom_fields.types', type] }.merge(interpolation))
    end

  end
end
