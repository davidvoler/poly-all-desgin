///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsHe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsHe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.he,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <he>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsHe _root = this; // ignore: unused_field

	@override 
	TranslationsHe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsHe(meta: meta ?? this.$meta);

	// Translations
	@override String get brand => 'POLYGLOTS';
	@override late final _TranslationsCommonHe common = _TranslationsCommonHe._(_root);
	@override late final _TranslationsHomeHe home = _TranslationsHomeHe._(_root);
}

// Path: common
class _TranslationsCommonHe extends TranslationsCommonEn {
	_TranslationsCommonHe._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String streak_days({required Object n}) => 'רצף של ${n} ימים';
	@override String streak_short({required Object n}) => '${n}';
	@override String get back => 'חזרה';
	@override String get skip => 'דלג';
	@override String get kContinue => 'המשך';
}

// Path: home
class _TranslationsHomeHe extends TranslationsHomeEn {
	_TranslationsHomeHe._(TranslationsHe root) : this._root = root, super.internal(root);

	final TranslationsHe _root; // ignore: unused_field

	// Translations
	@override String complete({required Object percent}) => '${percent}% הושלמו';
	@override String get course_overline => 'יפנית · ניהונגו';
	@override String get course_title => 'יפנית למתחילים';
	@override String get course_module => 'מודול 3 · ברכות והיכרות';
	@override String get tap_to_change => 'הקש לשינוי';
	@override String get vocabulary_label => '— אוצר המילים שלך —';
	@override String get stat_words => 'מילים';
	@override String get stat_sentences => 'משפטים';
	@override String get stat_exercises => 'תרגילים';
	@override String get practice_now => 'תרגל עכשיו';
	@override String get settings_tooltip => 'הגדרות';
}

/// The flat map containing all translations for locale <he>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsHe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'brand' => 'POLYGLOTS',
			'common.streak_days' => ({required Object n}) => 'רצף של ${n} ימים',
			'common.streak_short' => ({required Object n}) => '${n}',
			'common.back' => 'חזרה',
			'common.skip' => 'דלג',
			'common.kContinue' => 'המשך',
			'home.complete' => ({required Object percent}) => '${percent}% הושלמו',
			'home.course_overline' => 'יפנית · ניהונגו',
			'home.course_title' => 'יפנית למתחילים',
			'home.course_module' => 'מודול 3 · ברכות והיכרות',
			'home.tap_to_change' => 'הקש לשינוי',
			'home.vocabulary_label' => '— אוצר המילים שלך —',
			'home.stat_words' => 'מילים',
			'home.stat_sentences' => 'משפטים',
			'home.stat_exercises' => 'תרגילים',
			'home.practice_now' => 'תרגל עכשיו',
			'home.settings_tooltip' => 'הגדרות',
			_ => null,
		};
	}
}
