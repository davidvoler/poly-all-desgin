///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'POLYGLOTS'
	String get brand => 'POLYGLOTS';

	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsHomeEn home = TranslationsHomeEn.internal(_root);
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '{n} day streak'
	String get streak_days => '{n} day streak';

	/// en: '{n}'
	String get streak_short => '{n}';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Skip'
	String get skip => 'Skip';

	/// en: 'Continue'
	String get kContinue => 'Continue';
}

// Path: home
class TranslationsHomeEn {
	TranslationsHomeEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '{percent}% Complete'
	String get complete => '{percent}% Complete';

	/// en: 'Japanese · Nihongo'
	String get course_overline => 'Japanese · Nihongo';

	/// en: 'Japanese for Beginners'
	String get course_title => 'Japanese for Beginners';

	/// en: 'Module 3 · Greetings & Introductions'
	String get course_module => 'Module 3 · Greetings & Introductions';

	/// en: 'TAP TO CHANGE'
	String get tap_to_change => 'TAP TO CHANGE';

	/// en: '— Your Vocabulary —'
	String get vocabulary_label => '— Your Vocabulary —';

	/// en: 'Words'
	String get stat_words => 'Words';

	/// en: 'Lessons'
	String get stat_lessons => 'Lessons';

	/// en: 'Sentences'
	String get stat_sentences => 'Sentences';

	/// en: 'Practice Now'
	String get practice_now => 'Practice Now';

	/// en: 'Settings'
	String get settings_tooltip => 'Settings';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'brand' => 'POLYGLOTS',
			'common.streak_days' => '{n} day streak',
			'common.streak_short' => '{n}',
			'common.back' => 'Back',
			'common.skip' => 'Skip',
			'common.kContinue' => 'Continue',
			'home.complete' => '{percent}% Complete',
			'home.course_overline' => 'Japanese · Nihongo',
			'home.course_title' => 'Japanese for Beginners',
			'home.course_module' => 'Module 3 · Greetings & Introductions',
			'home.tap_to_change' => 'TAP TO CHANGE',
			'home.vocabulary_label' => '— Your Vocabulary —',
			'home.stat_words' => 'Words',
			'home.stat_lessons' => 'Lessons',
			'home.stat_sentences' => 'Sentences',
			'home.practice_now' => 'Practice Now',
			'home.settings_tooltip' => 'Settings',
			_ => null,
		};
	}
}
