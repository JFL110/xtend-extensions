package org.jfl110.xtend

import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.TransformationContext

/**
 * Helper to work out the JSON name of a field.
 */
class JsonDataFieldNameHelper {
	def jsonParamName(MutableFieldDeclaration field, TransformationContext context) {
		var existingAnnotation = field.findAnnotation(context.findTypeGlobally(JsonDataField));
		if (existingAnnotation !== null) {
			var fieldName = existingAnnotation.getValue("value");
			if (fieldName !== null) {
				return fieldName;
			}
		}

		return field.simpleName;
	}
}
