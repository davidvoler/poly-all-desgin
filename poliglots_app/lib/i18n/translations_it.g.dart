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
class TranslationsIt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsIt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.it,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <it>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsIt _root = this; // ignore: unused_field

	@override 
	TranslationsIt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsIt(meta: meta ?? this.$meta);

	// Translations
	@override String get brand => 'POLYGLOTS';
	@override late final _TranslationsCommonIt common = _TranslationsCommonIt._(_root);
	@override late final _TranslationsHomeIt home = _TranslationsHomeIt._(_root);
}

// Path: common
class _TranslationsCommonIt extends TranslationsCommonEn {
	_TranslationsCommonIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String streak_days({required Object n}) => 'Serie di ${n} giorni';
	@override String streak_short({required Object n}) => '${n}';
	@override String get back => 'Indietro';
	@override String get skip => 'Salta';
	@override String get kContinue => 'Continua';
}

// Path: home
class _TranslationsHomeIt extends TranslationsHomeEn {
	_TranslationsHomeIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String complete({required Object percent}) => '${percent}% Completato';
	@override String get course_overline => 'Giapponese · Nihongo';
	@override String get course_title => 'Giapponese per Principianti';
	@override String get course_module => 'Modulo 3 · Saluti e Presentazioni';
	@override String get tap_to_change => 'Tocca per cambiare';
	@override String get vocabulary_label => '— Il tuo vocabolario —';
	@override String get stat_words => 'Parole';
	@override String get stat_sentences => 'Frasi';
	@override String get stat_exercises => 'Esercizi';
	@override String get practice_now => 'Esercitati ora';
	@override String get settings_tooltip => 'Impostazioni';
}

/// The flat map containing all translations for locale <it>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsIt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'brand' => 'POLYGLOTS',
			'common.streak_days' => ({required Object n}) => 'Serie di ${n} giorni',
			'common.streak_short' => ({required Object n}) => '${n}',
			'common.back' => 'Indietro',
			'common.skip' => 'Salta',
			'common.kContinue' => 'Continua',
			'home.complete' => ({required Object percent}) => '${percent}% Completato',
			'home.course_overline' => 'Giapponese · Nihongo',
			'home.course_title' => 'Giapponese per Principianti',
			'home.course_module' => 'Modulo 3 · Saluti e Presentazioni',
			'home.tap_to_change' => 'Tocca per cambiare',
			'home.vocabulary_label' => '— Il tuo vocabolario —',
			'home.stat_words' => 'Parole',
			'home.stat_sentences' => 'Frasi',
			'home.stat_exercises' => 'Esercizi',
			'home.practice_now' => 'Esercitati ora',
			'home.settings_tooltip' => 'Impostazioni',
			_ => null,
		};
	}
}
