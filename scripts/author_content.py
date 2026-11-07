"""ARC-04 / LES-15: adds units, node types and per-node challenges to
app/assets/disciplines.json. Idempotent: base skills, questions and resources
already in the file are kept; generated nodes and fields are rebuilt.

All lesson wording here is original and AI-assisted (see README). It has not
been reviewed by a subject expert. Physical work stays self-reported: Music
items never listen to audio and Fashion items never inspect a garment.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / 'app/assets/disciplines.json'


# ---------------------------------------------------------------- helpers
def _c(cid, kind, prompt, explanation, options=(), answer=(), **content):
    content = {k: v for k, v in content.items() if v is not None}
    return dict(id=cid, kind=kind, prompt=prompt, explanation=explanation,
                options=list(options), answer=list(answer), content=content)


def par(prompt, options, answer, explanation, **content):
    p = dict(prompt=prompt, options=list(options), answer=list(answer), explanation=explanation)
    if content:
        p['content'] = content
    return p


def sel(cid, prompt, options, correct, explanation, hint=None, parallel=None, context=None):
    return _c(cid, 'singleSelect', prompt, explanation, options, [correct],
              hint=hint, parallel=parallel, context=context, skippable=True)


def order(cid, prompt, options, answer, explanation, hint=None, parallel=None, context=None):
    return _c(cid, 'sequenceTokens', prompt, explanation, options, answer,
              hint=hint, parallel=parallel, context=context)


def procedure(cid, prompt, options, answer, explanation, hint=None, parallel=None, context=None):
    return _c(cid, 'fashionProcedure', prompt, explanation, options, answer,
              hint=hint, parallel=parallel, context=context)


def match(cid, prompt, left, right, answer, explanation, hint=None, parallel=None, context=None):
    return _c(cid, 'matchPairs', prompt, explanation, left, answer, right=list(right),
              hint=hint, parallel=parallel, context=context)


def refl(cid, prompt, task, explanation):
    return _c(cid, 'typedReflection', prompt, explanation, task=task)


def observe(cid, prompt, reference, resource_id, explanation):
    return _c(cid, 'mediaObservation', prompt, explanation, reference=reference, resourceId=resource_id)


def tap(cid, prompt, explanation):
    return _c(cid, 'musicImitate', prompt, explanation)


def sketch(cid, prompt, explanation):
    return _c(cid, 'drawing', prompt, explanation)


def project(cid, prompt, task, rubric, explanation):
    return _c(cid, 'projectReflection', prompt, explanation, task=task, rubric=list(rubric))


# ---------------------------------------------------------------- Music
MUSIC = {
    'music-pulse': ('micro_lesson', [
        sel('pulse-1', 'What best describes the pulse of a piece?',
            ['The regular underlying beat', 'How loud it is', 'Every sound in the melody', 'The lyrics'], 0,
            'A pulse is the steady timing reference. Rhythms change around it.',
            hint='Think of what your foot taps while music plays.',
            parallel=par('Which part of the music stays even while a clapped pattern changes?',
                         ['The pulse', 'The words', 'The loudest note', 'The instrument'], [0],
                         'The pulse stays even while the rhythm on top of it changes.')),
        order('pulse-2', 'Build one bar of 4/4, starting from beat 1.', ['3', '1', '4', '2'], [1, 3, 0, 2],
              'Count 1, 2, 3, 4, then return to 1 for the next bar.',
              hint='Start on 1 and count upward.',
              parallel=par('Count one bar of 3/4, starting from beat 1.', ['2', '3', '1'], [2, 0, 1],
                           'A bar of 3/4 counts 1, 2, 3, then returns to 1.')),
        tap('pulse-3', 'Watch four beats, then tap five steady beats.',
            'Keep the spaces between taps even. Sumi measures screen taps only; audio is not recorded or graded.'),
        match('pulse-4', 'Match each idea to its meaning.', ['Pulse', 'Rhythm', 'Rest'],
              ['A silence that still takes time', 'The steady underlying beat',
               'Sounds and silences placed against the beat'],
              [1, 2, 0], 'Pulse is the beat; rhythm is the pattern on top; a rest is counted silence.',
              parallel=par('Match each word to what it describes.', ['Beat', 'Clap pattern', 'Counted silence'],
                           [1, 2, 0], 'A beat is the pulse; a clap pattern is a rhythm; counted silence is a rest.',
                           right=['A rest', 'The pulse', 'A rhythm'])),
    ]),
    'music-u1-video': ('video_resource', [
        observe('video-1',
                'Watch the pulse video, or read its summary. What stays the same while note lengths change?',
                'The video counts a steady beat while longer and shorter notes are placed above it. '
                'Notice that the counting never speeds up.',
                'music-pulse-video', 'Linking what you watched to the steady beat helps the next exercise.'),
        sel('video-2', 'In the video, longer notes are added above the count. What happens to the beat?',
            ['It stays at the same speed', 'It slows down to fit them', 'It stops', 'It gets louder'], 0,
            'The beat keeps its speed. Longer notes simply span more beats.',
            parallel=par('A slow melody plays over a steady count. What does the count do?',
                         ['It stays even', 'It follows the melody', 'It gets faster', 'It disappears'], [0],
                         'The count stays even; the melody moves at its own pace above it.')),
        refl('video-3', 'Name one moment where you could feel the beat continue through a silence.',
             'Write one sentence about where a silence still took time.',
             'Noticing counted silence prepares you for rests.'),
    ]),
    'music-duration': ('micro_lesson', [
        sel('duration-1', 'In 4/4 with a quarter-note beat, how long is a half note?',
            ['Half a beat', 'One beat', 'Two beats', 'Four bars'], 2,
            'A half note lasts two quarter-note beats in this example.',
            hint='A half note fills half of a four-beat bar.',
            parallel=par('In 4/4 with a quarter-note beat, how long is a whole note?',
                         ['One beat', 'Two beats', 'Three beats', 'Four beats'], [3],
                         'A whole note fills the whole four-beat bar.')),
        order('duration-2', 'Order these from shortest to longest.', ['Half note', 'Quarter note', 'Whole note'],
              [1, 0, 2],
              'Quarter (1 beat) is shorter than half (2 beats), which is shorter than whole (4 beats).',
              parallel=par('Order these rests from shortest to longest.', ['Whole rest', 'Quarter rest', 'Half rest'],
                           [1, 2, 0], 'Quarter rest (1 beat), half rest (2 beats), whole rest (4 beats).')),
        match('duration-3', 'Match each value to its length in 4/4.', ['Quarter note', 'Half note', 'Whole note'],
              ['Four beats', 'One beat', 'Two beats'], [1, 2, 0],
              'Quarter = 1 beat, half = 2 beats, whole = 4 beats when the quarter note gets the beat.'),
        sel('duration-4', 'A bar has a half note and a quarter note. What fills the last beat?',
            ['A quarter rest', 'A whole note', 'Another half note', 'Nothing is needed'], 0,
            'Two beats plus one beat is three; a one-beat rest completes four.',
            hint='Add the beats you already have.',
            parallel=par('A bar has three quarter notes. What completes it?',
                         ['One quarter note or rest', 'A half note', 'A whole rest', 'Two half notes'], [0],
                         'Three beats plus one more beat makes four.')),
        refl('duration-5', 'Write one four-beat bar using one rest.',
             'Write it with counts, for example: half note (1-2), quarter rest (3), quarter note (4).',
             'Counting the rest as carefully as the notes keeps the bar complete.'),
    ]),
    'music-phrase': ('micro_lesson', [
        sel('phrase-1', 'How many quarter-note beats fit in two complete bars of 4/4?',
            ['Two', 'Four', 'Six', 'Eight'], 3, 'Each bar has four beats, so two bars hold eight.',
            hint='Four beats per bar, two bars.',
            parallel=par('How many quarter-note beats are in three bars of 4/4?',
                         ['Seven', 'Nine', 'Twelve', 'Sixteen'], [2], 'Three bars of four beats give twelve.')),
        order('phrase-2', 'Put these steps for building a two-bar idea in order.',
              ['Change one thing in bar 2', 'Count bar 1', 'Repeat bar 1'], [1, 2, 0],
              'Count a clear first bar, repeat it, then make one deliberate change.',
              parallel=par('Order the steps for checking a new phrase.',
                           ['Perform it twice', 'Check each bar adds to four', 'Write the rhythm'], [2, 1, 0],
                           'Write it, check every bar adds up, then perform it.')),
        match('phrase-3', 'Match each term to its meaning.', ['Bar', 'Time signature', 'Phrase'],
              ['A short musical idea across bars', 'A group of beats', 'How many beats each bar holds'], [1, 2, 0],
              'A bar groups beats; the time signature sets how many; a phrase is an idea that spans bars.'),
        refl('phrase-4', 'Describe your two-bar idea in words.',
             'Say what repeats and what you changed in bar 2.',
             'Naming the repeat and the change makes the idea easy to remember.'),
    ]),
    'music-u1-review': ('recall_review', [
        sel('review-1', 'Your foot taps evenly while your claps change. What is your foot keeping?',
            ['The pulse', 'The melody', 'The lyrics', 'The key'], 0,
            'Even taps keep the pulse while claps make a rhythm.',
            parallel=par('A drummer keeps an even click while a singer changes rhythm. What does the click keep?',
                         ['The pulse', 'The tune', 'The words', 'The volume'], [0], 'The click keeps the pulse.')),
        match('review-2', 'Match each note value to its beats in 4/4.', ['Half note', 'Quarter rest', 'Whole note'],
              ['Four beats', 'Two beats', 'One beat'], [1, 2, 0],
              'Half = 2, quarter rest = 1, whole = 4.'),
        sel('review-3', 'One bar of 4/4 has only three beats so far. What completes it?',
            ['One quarter rest', 'A whole note', 'Three half notes', 'Nothing'], 0,
            'A one-beat rest brings the total to four.'),
    ]),
    'music-u1-checkpoint': ('checkpoint', [
        sel('cp1-1',
            'A song in 4/4 has a long held note over two beats, then two short sounds. How many beats so far?',
            ['Two', 'Three', 'Four', 'Six'], 2,
            'The held note covers two beats and the two short sounds take one beat each: four.',
            context='transfer'),
        order('cp1-2', 'Order a bar of 4/4 that ends with a rest.',
              ['Quarter rest (beat 4)', 'Half note (beats 1-2)', 'Quarter note (beat 3)'],
              [1, 2, 0], 'Beats 1-2 are the half note, beat 3 is the quarter note, beat 4 is the rest.'),
        match('cp1-3', 'Match each everyday example to the musical idea.',
              ['A ticking clock', 'A knock pattern on a door', 'A pause before an answer'],
              ['Rest', 'Pulse', 'Rhythm'], [1, 2, 0],
              'Steady ticks are like a pulse; a knock pattern is a rhythm; a timed pause is like a rest.',
              context='transfer'),
        tap('cp1-4', 'Tap five steady beats at a comfortable speed.',
            'Even spacing shows a steady pulse. Screen taps only; audio is not graded.'),
    ]),
    'music-u1-reward': ('reward_unlock', [
        match('reward1-1', 'Unit recap: match each word to its meaning.', ['Pulse', 'Duration', 'Phrase'],
              ['A short idea across bars', 'The steady beat', 'How long a sound lasts'], [1, 2, 0],
              'You can now count a pulse, measure length and shape a small phrase.'),
        refl('reward1-2', 'Name one thing you can do now that you could not do at the start of this unit.',
             'One sentence is enough.', 'Noticing your progress helps you choose the next step.'),
    ]),
    'music-pitch': ('micro_lesson', [
        sel('pitch-1', 'Which word describes how high or low a note sounds?',
            ['Tempo', 'Loudness', 'Pitch', 'Duration'], 2,
            'Pitch is high or low; tempo is speed; duration is length.',
            hint='It is not about speed or volume.',
            parallel=par('A singer moves to a higher note. Which property changed?',
                         ['Pitch', 'Tempo', 'Duration', 'Loudness'], [0], 'Moving higher changes pitch.')),
        order('pitch-2', 'Arrange these note names from low to high.', ['E', 'C', 'D'], [1, 2, 0],
              'In this register C is lowest, then D, then E.',
              parallel=par('Arrange from low to high.', ['G', 'E', 'F'], [1, 2, 0], 'E, then F, then G.')),
        sketch('pitch-3', 'Draw an up–down–up contour and label one note name at each turn.',
               'A contour drawing records the shape of a melody. Sumi does not grade the drawing.'),
        match('pitch-4', 'Match each change to the property it affects.',
              ['Play more quietly', 'Move from C to E', 'Hold the note longer'],
              ['Duration', 'Loudness', 'Pitch'], [1, 2, 0],
              'Quieter changes loudness; C to E changes pitch; holding changes duration.'),
    ]),
    'music-u2-video': ('video_resource', [
        observe('video2-1', 'Watch the pitch video, or read its summary. How does the staff show higher notes?',
                'The video shows notes placed higher on the staff for higher pitches and lower for lower pitches, '
                'with letter names attached.',
                'music-pitch-video', 'Connecting position on the staff to pitch helps you read simple melodies.'),
        sel('video2-2', 'A note moves up one line on the staff. What usually happens to its pitch?',
            ['It gets higher', 'It gets lower', 'It gets louder', 'It gets longer'], 0,
            'Higher on the staff means higher in pitch.',
            parallel=par('A note moves down the staff. What happens to its pitch?',
                         ['It gets lower', 'It gets higher', 'It gets quieter', 'It stops'], [0],
                         'Lower on the staff means lower in pitch.')),
        refl('video2-3', 'Describe the shape of a melody you know: does it start by going up or down?',
             'One or two sentences.', 'Describing contour in words is a first step toward reading it.'),
    ]),
    'music-practice': ('guided_practice', [
        sel('practice-1', 'A pattern becomes uneven at a fast tempo. What is a useful next step?',
            ['Speed up again', 'Slow down and isolate the hard part', 'Ignore timing', 'Only play louder'], 1,
            'A slower, focused repetition makes the difficulty easier to notice and fix.',
            hint='Which choice gives you more time to notice what happens?',
            parallel=par('You keep stumbling on bar 3. What should you practise?',
                         ['Bar 3 slowly on its own', 'The whole piece faster', 'Only bar 1', 'Nothing'], [0],
                         'Isolating the difficult bar at a slower speed targets the problem.')),
        order('practice-2', 'Put this practice loop in order.',
              ['Adjust one thing', 'Set a small target', 'Try it twice', 'Notice what changed'],
              [1, 2, 3, 0], 'Set a target, try it, notice what happened, then adjust one thing.'),
        tap('practice-3', 'Tap five steady beats slowly, as if practising carefully.',
            'Slower, even taps show control. Screen taps only; audio is not graded.'),
        sel('practice-4', 'Which practice goal is easiest to check?',
            ['Become amazing today', 'Be more musical', 'Keep four bars even twice in a row', 'Never make a mistake'], 2,
            'A short observable target gives you something concrete to compare.'),
        refl('practice-5', 'Record one difficulty and one change you made.',
             'Try your two-bar pattern twice, then write what was hard and what you changed.',
             'A specific observation suggests your next adjustment.'),
    ]),
    'music-create': ('project_step', [
        sel('create-1', 'Which check is most useful before performing a new 4/4 rhythm?',
            ['Its title has four words', 'Every bar totals four beats', 'Every sound is loud', 'There are no rests'], 1,
            'Checking each bar’s total confirms the rhythm fits the meter.',
            parallel=par('Before sharing a new 3/4 rhythm, what should each bar total?',
                         ['Two beats', 'Three beats', 'Four beats', 'Six beats'], [1],
                         'In 3/4 each bar holds three beats.')),
        match('create-2', 'Match each review note to what it tells you.',
              ['Bar three rushed', 'I slowed down and it was steadier', 'Next: repeat bar three slowly'],
              ['A next action', 'Where the problem was', 'What helped this attempt'], [1, 2, 0],
              'Good reviews say where, what helped, and what to do next.'),
        project('create-3', 'Make an original four-bar rhythm and review it.',
                'Use paper, clapping or an instrument. Mark one rest, perform it twice and compare the attempts.',
                ['Every bar adds to four', 'One rest is marked', 'Performed twice', 'One change named'],
                'Your project evidence is saved as your own report. Sumi does not listen to or grade the performance.'),
    ]),
    'music-u2-checkpoint': ('checkpoint', [
        sel('cp2-1', 'A phone ringtone goes low, high, low. What is its contour?',
            ['Up then down', 'Down then up', 'Flat', 'Always rising'], 0,
            'Low to high is up; high to low is down.', context='transfer'),
        order('cp2-2', 'Order these steps to fix a rushed bar.',
              ['Join it back into the phrase', 'Play the bar slowly alone', 'Find which bar rushed'],
              [2, 1, 0], 'Find the bar, practise it slowly, then rejoin the phrase.'),
        match('cp2-3', 'Match each situation to the best practice move.',
              ['Notes are wrong', 'Timing is uneven', 'It sounds right twice'],
              ['Try a slightly faster tempo', 'Check the note names slowly', 'Slow down and count aloud'], [1, 2, 0],
              'Fix accuracy first, then timing, and only then speed.', context='transfer'),
        sel('cp2-4', 'A melody is played louder but on the same notes. What changed?',
            ['Loudness', 'Pitch', 'The note names', 'The contour'], 0, 'Volume changed; pitch and contour did not.'),
    ]),
    'music-u2-reward': ('reward_unlock', [
        match('reward2-1', 'Unit recap: match each skill to an example.', ['Pitch', 'Practice', 'Creating'],
              ['Write and review your own rhythm', 'Hear that E is higher than C', 'Slow down to fix bar three'],
              [1, 2, 0],
              'You can now follow pitch, practise with a target and make your own idea.'),
        refl('reward2-2', 'What would you like to make next with what you learned?',
             'One sentence is enough.', 'A next goal keeps practice connected to what you want to do.'),
    ]),
}

MUSIC_UNITS = [
    dict(id='music-unit-1', title='Pulse, length and phrase', outcome='Count a steady pulse and build complete bars.',
         palette=0,
         nodes=['music-pulse', 'music-u1-video', 'music-duration', 'music-phrase', 'music-u1-review',
                'music-u1-checkpoint', 'music-u1-reward'],
         guide=dict(key_ideas=['The pulse is a steady beat; rhythm sits on top of it.',
                               'In 4/4 a quarter note is one beat, a half note two, a whole note four.',
                               'A rest still takes time, so keep counting.',
                               'A phrase is a short idea across bars: repeat, then change one thing.'],
                    watch=['music-pulse-video'],
                    reference=['music-pulse-reference', 'music-duration-reference', 'music-phrase-reference'],
                    tryit='Clap two bars of 4/4 with one rest while tapping the pulse with your foot.')),
    dict(id='music-unit-2', title='Pitch, practice and your own idea',
         outcome='Follow a pitch shape and practise toward a small original rhythm.',
         palette=1,
         nodes=['music-pitch', 'music-u2-video', 'music-practice', 'music-create', 'music-u2-checkpoint',
                'music-u2-reward'],
         guide=dict(key_ideas=['Pitch is high or low; loudness is separate.',
                               'Higher on the staff means higher in pitch.',
                               'Practise slowly with one observable target.',
                               'Review where, what helped, and what to try next.'],
                    watch=['music-pitch-video'],
                    reference=['music-pitch-reference', 'music-practice-reference', 'music-create-reference'],
                    tryit='Make a four-bar rhythm with one rest, perform it twice and note one change.')),
]

# ---------------------------------------------------------------- Fashion
FASHION = {
    'fashion-brief': ('micro_lesson', [
        sel('brief-1', 'Which detail belongs in a useful design brief?',
            ['Only a favourite colour', 'The intended use and the wearer’s needs', 'Only a brand name',
             'A price with no context'], 1,
            'Use and wearer needs give each design decision a purpose.',
            hint='What would help someone decide the size and features?',
            parallel=par('Which line makes a brief more useful?',
                         ['For carrying two sketchbooks every day', 'It should be nice', 'Blue', 'Expensive'], [0],
                         'A stated use tells you what the design must do.')),
        match('brief-2', 'Match each brief line to what it decides.', ['Who it is for', 'When it is used', 'A constraint'],
              ['Must fold flat for travel', 'A student carrying notebooks', 'Daily commute'], [1, 2, 0],
              'A brief names the wearer, the use and the constraints.',
              parallel=par('Match each note to its role in a brief.', ['Wearer', 'Occasion', 'Limit'], [2, 0, 1],
                           'Wearer, occasion and limits each shape the design.',
                           right=['Evening event', 'Under 3 metres of fabric', 'A child aged six'])),
        sketch('brief-3', 'Sketch the front of your item and label two features.',
               'A labelled sketch records your plan. Sumi does not inspect drawings or garments.'),
        sel('brief-4', 'Which sketch note best links a feature to its purpose?',
            ['Add something nice', 'A wider opening lets the notebook slide in', 'Make every detail bigger',
             'No labels needed'], 1,
            'It explains why the feature exists and what it should achieve.'),
        refl('brief-5', 'Write a three-line brief for an item of your choice.',
             'Line 1: who it is for. Line 2: when it is used. Line 3: one constraint.',
             'A short, specific brief guides every later decision.'),
    ]),
    'fashion-u1-video': ('video_resource', [
        observe('fvideo-1',
                'Watch the brief and sketching video, or read its summary. What does the designer write before sketching?',
                'The video starts with a written brief (who, when, why) and only then sketches the silhouette '
                'with labelled features.',
                'fashion-brief-video', 'Writing the brief first keeps the sketch purposeful.'),
        sel('fvideo-2', 'Why write the brief before sketching?',
            ['So each sketched feature has a reason', 'Because sketches are not allowed', 'To skip measuring',
             'To choose a brand'], 0,
            'The brief gives each feature a purpose to check against.',
            parallel=par('A designer sketches a pocket. What should the brief tell them?',
                         ['What the pocket must hold', 'The designer’s age', 'The shop name', 'Nothing'], [0],
                         'The brief says what the feature must do.')),
        refl('fvideo-3', 'Name one feature you would label on your own sketch and why.',
             'One sentence.', 'Linking a feature to its purpose is the core of a brief.'),
    ]),
    'fashion-fabric': ('micro_lesson', [
        sel('fabric-1', 'On a woven fabric, the lengthwise grain runs…',
            ['Diagonally to the selvage', 'Parallel to the selvage', 'Only around curves', 'In no direction'], 1,
            'The lengthwise grain runs parallel to the selvage.',
            hint='The selvage is the finished edge of the fabric.',
            parallel=par('Which edge does the lengthwise grain follow?',
                         ['The selvage', 'The cut edge', 'A diagonal fold', 'Any edge'], [0],
                         'It follows the selvage, the woven finished edge.')),
        match('fabric-2', 'Match each fabric property to what it affects.', ['Stretch', 'Thickness', 'Fraying'],
              ['Whether edges need finishing', 'How the item fits and moves', 'How stiff and warm it is'], [1, 2, 0],
              'Stretch affects fit, thickness affects body, fraying affects edge finishing.'),
        sel('fabric-3', 'A pattern asks for a stretch knit. What should you check before substituting?',
            ['Only the colour', 'Its stretch and behaviour', 'The price tag font', 'The packaging'], 1,
            'Changing stretch changes fit and construction.'),
        refl('fabric-4', 'Compare two fabrics you can see or read about.',
             'Note stretch, thickness and fraying for each, then say which suits your brief.',
             'A side-by-side comparison makes the choice explainable.'),
    ]),
    'fashion-measure': ('guided_practice', [
        sel('measure-1', 'Which measurement record is clearest?', ['Width: 12', 'Width: 12 cm', 'About 12', 'Size: nice'],
            1,
            'A named dimension with a unit can be repeated and compared.',
            hint='What would someone else need to repeat it?',
            parallel=par('Which record could someone else repeat?',
                         ['Height: 18 cm, measured at the centre', 'Tall', '18', 'Big enough'], [0],
                         'It names the dimension, unit and method.')),
        procedure('measure-2', 'Put these measuring steps in order.',
                  ['Record with units', 'Measure once', 'Lay the object flat', 'Measure again and compare'],
                  [2, 1, 3, 0], 'Lay it flat, measure, re-measure to compare, then record with units.',
                  parallel=par('Order these steps for checking a measurement.',
                               ['Write it down', 'Repeat the reading', 'Take the first reading'],
                               [2, 1, 0], 'Take a reading, repeat it, then write it down.')),
        sel('measure-3', 'One reading is in inches and another in centimetres. What first?',
            ['Assume they match', 'Pick the bigger number', 'Convert to one unit', 'Ignore the labels'], 2,
            'Compare only after converting to a common unit.'),
        refl('measure-4', 'Measure a notebook twice and record both readings.',
             'Label width and height with units, then say whether the two readings agree.',
             'Repeating a measurement catches small mistakes before cutting.'),
    ]),
    'fashion-u1-review': ('recall_review', [
        sel('freview-1', 'Which brief line explains a feature’s purpose?',
            ['A long strap so it can be worn across the body', 'Make it pretty', 'Green', 'Large'], 0,
            'It ties a feature to how the item is used.',
            parallel=par('Which note gives a reason for a feature?',
                         ['A lined pocket keeps pens from marking the fabric', 'Add pockets', 'Red lining', 'Small'],
                         [0],
                         'It says why the feature exists.')),
        match('freview-2', 'Match each term to its meaning.', ['Selvage', 'Grainline', 'Unit'],
              ['cm or inches', 'The finished woven edge', 'The direction pieces are aligned'], [1, 2, 0],
              'Selvage is the finished edge, grainline is alignment, and a unit makes a measurement usable.'),
        sel('freview-3', 'Two width readings differ. What next?',
            ['Cut immediately', 'Remeasure with the same method', 'Average without checking', 'Remove the unit'], 1,
            'Repeating the method can reveal why they differ.'),
    ]),
    'fashion-u1-checkpoint': ('checkpoint', [
        sel('fcp1-1', 'A raincoat brief says “must keep a laptop dry”. Which choice follows from it?',
            ['A water-resistant fabric and covered opening', 'The brightest colour', 'The thinnest knit',
             'No closure'], 0,
            'The brief’s need decides the material and the opening.', context='transfer'),
        procedure('fcp1-2', 'Order the planning steps for a new apron.',
                  ['Choose fabric', 'Write the brief', 'Measure the wearer’s needs on paper'],
                  [1, 2, 0], 'Brief first, then measurements, then a fabric that suits both.'),
        match('fcp1-3', 'Match each problem to its likely cause.',
              ['Seam stretches out', 'Edges unravel', 'Readings disagree'],
              ['Different measuring method', 'Knit used where a woven was expected',
               'Fabric frays and needs finishing'], [1, 2, 0],
              'Stretch, fraying and inconsistent methods each cause a different problem.', context='transfer'),
        sel('fcp1-4', 'Which record is ready to plan from?',
            ['32', 'Waist-ish 32', 'Bag width: 32 cm, measured twice', 'Roomy'], 2,
            'It names the dimension, the unit and that it was checked.'),
    ]),
    'fashion-u1-reward': ('reward_unlock', [
        match('freward1-1', 'Unit recap: match each skill to an example.', ['Brief', 'Fabric', 'Measuring'],
              ['Width: 12 cm, measured twice', 'For carrying sketchbooks daily', 'Woven, low stretch, frays'],
              [1, 2, 0],
              'You can now write a brief, describe fabric and record measurements.'),
        refl('freward1-2', 'Name one decision you would make differently now that you know about fabric.',
             'One sentence.', 'Seeing how your choices changed is real progress.'),
    ]),
    'fashion-pattern': ('micro_lesson', [
        sel('pattern-1', 'What is a seam allowance?',
            ['Extra fabric between the stitch line and the cut edge', 'A decorative line', 'The whole garment width',
             'A universal size'], 0,
            'It is the width outside the stitching line used to join pieces.',
            hint='It sits between two lines on the pattern.',
            parallel=par('On a pattern piece, what is between the stitch line and the cut line?',
                         ['The seam allowance', 'The grainline', 'The hem fold', 'Nothing'], [0],
                         'That margin is the seam allowance.')),
        sel('pattern-2', 'A finished width is 12 cm with 1 cm allowance each side. What is the cut width?',
            ['12 cm', '13 cm', '14 cm', '24 cm'], 2, 'Add 1 cm on the left and 1 cm on the right: 14 cm.',
            hint='There are two sides.',
            parallel=par('A finished width is 8 cm with 1.5 cm allowance each side. What is the cut width?',
                         ['9.5 cm', '10 cm', '11 cm', '12 cm'], [2], 'Add 1.5 cm twice: 11 cm.')),
        procedure('pattern-3', 'Order the steps to draft a simple pattern piece.',
                  ['Add seam allowance', 'Draw the finished shape', 'Mark the grainline', 'Label both lines'],
                  [1, 2, 0, 3], 'Draw the finished shape, mark grain, add allowance, then label.'),
        sketch('pattern-4', 'Draw an 8 × 10 cm finished rectangle and a 1 cm allowance around it.',
               'Your drawing records the plan. Sumi does not measure it.'),
    ]),
    'fashion-u2-video': ('video_resource', [
        observe('fvideo2-1',
                'Watch the grainline and seam video, or read its summary. What is tested before the final seam?',
                'The video tests a seam on scrap fabric first, checking that the allowance stays even and the '
                'fabric does not pucker.',
                'fashion-seam-video', 'Testing on scrap protects your final pieces.'),
        sel('fvideo2-2', 'Why sew a test seam on scrap?',
            ['To check the join before the final fabric', 'To skip measuring', 'To remove the allowance',
             'To hide the stitch line'], 0,
            'A sample reveals problems before they reach the final piece.',
            parallel=par('What does a scrap test protect?',
                         ['Your final fabric', 'The sewing manual', 'The scissors', 'The sketch'], [0],
                         'Problems are found on scrap, not on the final piece.')),
        refl('fvideo2-3', 'Name one thing you would check on a test seam.', 'One sentence.',
             'Choosing what to check makes the test useful.'),
    ]),
    'fashion-seam': ('project_step', [
        sel('seam-1', 'A seam sample puckers. What is a sensible next step?',
            ['Use it on the final piece', 'Adjust handling or settings and test another scrap',
             'Cut away the allowance', 'Stop recording'], 1,
            'Change one thing and test again on scrap.',
            parallel=par('A test seam wanders off the marked line. What next?',
                         ['Mark the line clearly and try another scrap', 'Sew the final piece anyway',
                          'Remove the mark', 'Stop'], [0],
                         'Improve the guide and test again.')),
        procedure('seam-2', 'Order the sample-seam steps.',
                  ['Inspect width and puckering', 'Align the edges', 'Mark the seam line', 'Join the sample'],
                  [1, 2, 3, 0], 'Align, mark, join, then inspect.'),
        project('seam-3', 'Make a paper mockup or a scrap seam sample.',
                'Mark the seam line, join the pieces, and inspect whether the width stays even.',
                ['Allowance stays even', 'Edges aligned', 'No puckering', 'One change named'],
                'Your project evidence is saved as your own report. Sumi does not inspect the sample.'),
    ]),
    'fashion-finish': ('project_step', [
        sel('finish-1', 'What should guide an edge finish?',
            ['Only speed', 'The fabric, construction and intended use', 'A random width', 'The date'], 1,
            'Material and use decide a suitable finish.',
            parallel=par('Which fact matters most when choosing an edge finish?',
                         ['Whether the fabric frays', 'The thread brand', 'The day of the week', 'The pattern name'],
                         [0],
                         'Fraying fabric needs an edge that controls it.')),
        match('finish-2', 'Match each review question to what it checks.',
              ['Does it hold the notebook?', 'Are the seams secure?', 'Is the edge clean?'],
              ['Finishing', 'Function', 'Construction'], [1, 2, 0],
              'A final review checks function, construction and finishing against the brief.'),
        project('finish-3', 'Review your mockup or sample against your brief.',
                'Note one thing that works and one concrete change.',
                ['Compared with the brief', 'Function checked', 'Edges checked', 'One change named'],
                'This is a self-review, not a professional construction grade.'),
    ]),
    'fashion-u2-checkpoint': ('checkpoint', [
        sel('fcp2-1', 'A cushion cover finishes at 40 cm with 1 cm allowance each side. What is the cut width?',
            ['40 cm', '41 cm', '42 cm', '44 cm'], 2, 'Add 1 cm on each side: 42 cm.', context='transfer'),
        procedure('fcp2-2', 'Order the steps from pattern to sample.',
                  ['Inspect the sample', 'Add allowance to the pattern', 'Cut and join a scrap sample'],
                  [1, 2, 0], 'Pattern with allowance, then sample, then inspect.'),
        match('fcp2-3', 'Match each finished-item problem to a fix to test.',
              ['Opening too narrow', 'Edge frays', 'Seam puckers'],
              ['Adjust handling on a scrap test', 'Widen the mockup opening', 'Add a suitable edge finish'],
              [1, 2, 0],
              'Each problem points to one change to test.', context='transfer'),
        sel('fcp2-4', 'Which note gives a useful next alteration?',
            ['Make it better', 'Everything is perfect', 'The strap is 5 cm too short; lengthen the mockup',
             'Short title'], 2,
            'It names a measurable problem and a specific change.'),
    ]),
    'fashion-u2-reward': ('reward_unlock', [
        match('freward2-1', 'Unit recap: match each skill to an example.', ['Pattern', 'Sample seam', 'Review'],
              ['Compare the result with the brief', 'Add 1 cm allowance to each edge',
               'Test the join on scrap first'], [1, 2, 0],
              'You can now draft with allowance, test a seam and review against a brief.'),
        refl('freward2-2', 'What would you like to make next?', 'One sentence.',
             'A next project keeps your skills growing.'),
    ]),
}

FASHION_UNITS = [
    dict(id='fashion-unit-1', title='Brief, fabric and measuring',
         outcome='Write a clear brief, choose suitable fabric and record repeatable measurements.',
         palette=0,
         nodes=['fashion-brief', 'fashion-u1-video', 'fashion-fabric', 'fashion-measure', 'fashion-u1-review',
                'fashion-u1-checkpoint', 'fashion-u1-reward'],
         guide=dict(key_ideas=['A brief names the wearer, the use and the constraints.',
                               'Lengthwise grain runs parallel to the selvage.',
                               'Stretch, thickness and fraying change how fabric behaves.',
                               'Record each measurement with its unit and repeat it.'],
                    watch=['fashion-brief-video'],
                    reference=['fashion-brief-reference', 'fashion-fabric-reference', 'fashion-measure-reference'],
                    tryit='Write a three-line brief, then measure a notebook twice and record both readings with units.')),
    dict(id='fashion-unit-2', title='Pattern to finished sample',
         outcome='Draft with seam allowance, test a seam on scrap and review the result.',
         palette=1,
         nodes=['fashion-pattern', 'fashion-u2-video', 'fashion-seam', 'fashion-finish', 'fashion-u2-checkpoint',
                'fashion-u2-reward'],
         guide=dict(key_ideas=['The seam allowance sits between the stitch line and the cut edge.',
                               'Cut width = finished width + allowance on each side.',
                               'Test a seam on scrap before the final piece.',
                               'Review the result against the brief and name one change.'],
                    watch=['fashion-seam-video'],
                    reference=['fashion-pattern-reference', 'fashion-seam-reference', 'fashion-finish-reference'],
                    tryit='Draft a paper rectangle with a 1 cm allowance, then make a scrap or paper seam sample.')),
]

TRACK_META = {
    'music': dict(evidence_categories=['concept', 'rhythm screen taps', 'resource observation', 'reflection'],
                  celebration='rhythm', default_accolade='listening', scene='music',
                  preview_capabilities=['Count a steady pulse and write complete bars in 4/4.',
                                        'Make and review a short original rhythm you can perform.',
                                        'Practise with a clear target and notice what to change.'],
                  outcome_chips=['Keep a steady rhythm', 'Write a four-bar pattern', 'Understand basic notation',
                                 'Practise a song effectively']),
    'fashion': dict(evidence_categories=['procedure', 'tools', 'annotated plan', 'reflection'],
                    celebration='stitches', default_accolade='making', scene='fashion',
                    preview_capabilities=['Write a design brief that explains each feature.',
                                          'Draft a simple pattern with the right seam allowance.',
                                          'Test a sample seam and review it against your brief.'],
                    outcome_chips=['Make a simple tote', 'Draft a basic pattern', 'Learn accurate measurements',
                                   'Build clean seams']),
}

GENERATED = {
    'video_resource': ('Watch and apply', 'A short video, then one question that uses it.'),
    'recall_review': ('Unit review', 'Bring back what you practised with new examples.'),
    'checkpoint': ('Unit checkpoint', 'New examples. Answer every check correctly to earn a star.'),
    'reward_unlock': ('Unit reward', 'A quick recap, then collect your sparks.'),
}


def apply(track, nodes, units):
    base = {s['id']: s for s in track['skills'] if not s.get('generated')}
    resources = {r['id'] for r in track['resources']}
    out = []
    previous = None
    for unit in units:
        for nid in unit['nodes']:
            ntype, challenges = nodes[nid]
            if nid in base:
                skill = dict(base[nid])
            else:
                title, subtitle = GENERATED[ntype]
                video = next((c['content'].get('resourceId') for c in challenges
                              if c['kind'] == 'mediaObservation'), None)
                skill = dict(id=nid, title=title, subtitle=subtitle,
                             minutes=8 if ntype == 'reward_unlock' else 10,
                             deliverable=subtitle, generated=True,
                             resource_id=video or unit['guide']['reference'][0])
            skill['type'] = ntype
            skill['unit_id'] = unit['id']
            skill['prerequisites'] = [previous] if previous else []
            skill['challenges'] = challenges
            assert skill['resource_id'] in resources, (nid, skill['resource_id'])
            out.append(skill)
            previous = nid
    track['skills'] = out
    track['units'] = [dict(id=u['id'], title=u['title'], outcome=u['outcome'], palette=u['palette'],
                           guide=dict(key_ideas=u['guide']['key_ideas'], watch=u['guide']['watch'],
                                      reference=u['guide']['reference'], tryit=u['guide']['tryit']))
                      for u in units]
    for u in units:
        for rid in u['guide']['watch'] + u['guide']['reference']:
            assert rid in resources, rid
    track.update(TRACK_META[track['id']])


def validate(track):
    ids = [s['id'] for s in track['skills']]
    assert len(ids) == len(set(ids))
    types = {s['type'] for s in track['skills']}
    assert types == {'micro_lesson', 'guided_practice', 'recall_review', 'video_resource', 'project_step',
                     'checkpoint', 'reward_unlock'}, types
    seen = set()
    for s in track['skills']:
        sig = json.dumps(s['challenges'], sort_keys=True)
        assert sig not in seen, s['id']
        seen.add(sig)
        assert len({c['kind'] for c in s['challenges']}) >= 2, s['id']
        cids = [c['id'] for c in s['challenges']]
        assert len(cids) == len(set(cids)), s['id']
        for c in s['challenges']:
            n = len(c['options'])
            if c['kind'] == 'singleSelect':
                assert len(c['answer']) == 1 and 0 <= c['answer'][0] < n, c['id']
            if c['kind'] in ('sequenceTokens', 'fashionProcedure', 'matchPairs'):
                assert sorted(c['answer']) == list(range(n)), c['id']
            if c['kind'] == 'matchPairs':
                assert len(c['content']['right']) == n, c['id']
            p = c['content'].get('parallel')
            if p:
                m = len(p['options'])
                if c['kind'] == 'singleSelect':
                    assert len(p['answer']) == 1 and 0 <= p['answer'][0] < m, c['id']
                else:
                    assert sorted(p['answer']) == list(range(m)), c['id']
                if c['kind'] == 'matchPairs':
                    assert len(p['content']['right']) == m, c['id']


if __name__ == '__main__':
    data = json.loads(PATH.read_text(encoding='utf-8'))
    for track in data['tracks']:
        if track['id'] == 'music':
            apply(track, MUSIC, MUSIC_UNITS)
        elif track['id'] == 'fashion':
            apply(track, FASHION, FASHION_UNITS)
        validate(track)
    PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    for t in data['tracks']:
        print(t['id'], len(t['skills']), 'nodes,', sum(len(s['challenges']) for s in t['skills']), 'challenges')
