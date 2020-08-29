package org.jfl110.xtend;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import org.eclipse.xtend.lib.macro.Active;

/**
 * 
 * 
 * See {@link org.eclipse.xtend.lib.annotations.Data}
 */
@Target(ElementType.TYPE)
@Active(JsonDataProcessor.class)
@Retention(RetentionPolicy.SOURCE)
@SuppressWarnings("all")
public @interface JsonData {
}