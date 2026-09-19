///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsAfr with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAfr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.afr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <afr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsAfr _root = this; // ignore: unused_field

	@override 
	TranslationsAfr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsAfr(meta: meta ?? this.$meta);

	// Translations
	@override String hello({required Object name}) => 'More ${name}';
	@override String get save => 'Save afr';
	@override late final _Translations$login$afr login = _Translations$login$afr._(_root);
}

// Path: login
class _Translations$login$afr implements Translations$login$en {
	_Translations$login$afr._(this._root);

	final TranslationsAfr _root; // ignore: unused_field

	// Translations
	@override String get success => 'afr Logged in successfully';
	@override String get fail => 'afr Logged in failed';
}

/// The flat map containing all translations for locale <afr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAfr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'hello' => ({required Object name}) => 'More ${name}',
			'save' => 'Save afr',
			'login.success' => 'afr Logged in successfully',
			'login.fail' => 'afr Logged in failed',
			_ => null,
		};
	}
}
