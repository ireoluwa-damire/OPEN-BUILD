"""Original bounded demo content for the two disciplines selected by the user."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
CALIBRATION = [
    dict(day=1, title='Choose, assess, and try', kind='baseline', description='Choose your discipline and goal. Complete the six-question baseline, try a project step, and download an optional phone model.'),
    dict(day=2, title='Return, recall, and review', kind='recall', description='Try six new examples, compare your work, test the coach with connectivity off, and record usability feedback. An early check-in is labelled as an accelerated demo.'),
]

def item(prompt, options, correct, explanation, hint='Break the idea into one small step.'):
    return dict(prompt=prompt, options=options, correct=correct, explanation=explanation, hint=hint)

def skill(key, title, subtitle, body, example, task, baseline, recall, practice, url, resource_title, publisher):
    return dict(key=key, title=title, subtitle=subtitle, body=body, example=example,
        task=task, baseline=baseline, recall=recall, practice=practice, url=url,
        resource_title=resource_title, publisher=publisher)

METER = 'https://viva.pressbooks.pub/openmusictheory/chapter/simple-meter-and-time-signatures/'
NOTES = 'https://www.musictheory.net/lessons/10'
RHYTHM = 'https://www.musictheory.net/lessons/11'
PRACTICE = 'https://viva.pressbooks.pub/openmusictheory/part/ear-training/'
music = [
    skill('pulse', 'Find a steady pulse', 'Keep the beat while the rhythm changes.',
        'A pulse is a regular underlying beat. A rhythm places sounds and silences against it. Tap four even beats first, then clap a pattern while your foot keeps the pulse. Start with counting rather than speed.',
        'Count:  1   2   3   4\nClap:   x       x   x',
        'Tap eight even beats and clap on beats one and three. Notice whether your foot speeds up when the claps change.',
        item('What best describes the pulse of a piece?', ['The regular underlying beat', 'How loud it is', 'Every sound in the melody', 'Its lyrics'], 0, 'A pulse provides a regular timing reference; the rhythm can change around it.'),
        item('You clap different patterns while tapping evenly. What is your foot keeping?', ['The melody', 'The pulse', 'The lyrics', 'The key signature'], 1, 'The even tapping maintains the pulse while your clapping creates a rhythm.'),
        item('Your claps change but your foot stays even. What stays consistent?', ['The pulse', 'Every note length', 'The melody', 'The volume'], 0, 'The pulse stays even even when the clapped rhythm changes.'),
        METER, 'Beat, grouping, and simple meter', 'Open Music Theory'),
    skill('duration', 'Give sounds a length', 'Count note values and rests in a simple meter.',
        'For this exercise in 4/4, a quarter note lasts one beat and a half note lasts two. A rest also occupies time. Keep counting during silence so the next sound starts in the right place.',
        '4/4 bar: half note + quarter note + quarter rest\nBeats:       2     +      1       +      1 = 4',
        'Write one four-beat bar using note lengths and a rest. Count the silence as carefully as the sounds.',
        item('In 4/4 with a quarter-note beat, how long is a half note?', ['Half a beat', 'One beat', 'Two beats', 'Four bars'], 2, 'A half note is two quarter-note beats in this example.'),
        item('How many quarter-note beats are left after a half note in one 4/4 bar?', ['One', 'Two', 'Three', 'Four'], 1, 'The bar holds four quarter-note beats, so four minus two leaves two.'),
        item('How many beats do a half note, a quarter note, and a quarter rest fill in 4/4?', ['Two', 'Three', 'Four', 'Five'], 2, 'Their lengths add to two plus one plus one: four beats.'),
        RHYTHM, 'Note duration and rests', 'musictheory.net'),
    skill('pitch', 'Follow a pitch shape', 'Separate high and low from loud and soft.',
        'Pitch describes how high or low a sound is; loudness is a different property. In the familiar ascending note-letter sequence, C to D to E moves upward. You can first draw that contour without singing or owning an instrument.',
        'Note names: C → D → E\nContour:    low → higher → higher',
        'Draw an up-down-up contour, then choose four note names that follow it. Use an instrument if available, or label a paper diagram.',
        item('Which word describes how high or low a note sounds?', ['Tempo', 'Loudness', 'Pitch', 'Duration'], 2, 'Pitch concerns high and low; tempo concerns speed and duration concerns length.'),
        item('A melody moves from C up to D up to E in the same register. What is its contour?', ['Upward', 'Downward', 'Unchanging', 'Always louder'], 0, 'The pitches rise. Rising pitch does not imply rising loudness.'),
        item('A note is played more quietly without changing its frequency. Which property changes?', ['Its pitch', 'Its loudness', 'Its note name', 'Its position in the scale'], 1, 'Playing more quietly changes loudness, not the note’s pitch.'),
        NOTES, 'Staff, note names, and pitch', 'musictheory.net'),
    skill('phrase', 'Shape a small phrase', 'Organize a pattern into bars.',
        'For a first example, use two bars of 4/4. Each bar contains four quarter-note beats. A repeat or a small change can make a short idea recognizable. Keep bar totals correct before adding detail.',
        'Bar 1: 1  2  3  4 | Bar 2: 1  2  3  4\nIdea:  x     x  x |        x  x     x',
        'Create two bars of counted rhythm. Repeat the first bar, then make one deliberate change in the second.',
        item('How many quarter-note beats fit in two complete bars of 4/4?', ['Two', 'Four', 'Six', 'Eight'], 3, 'Each bar has four quarter-note beats, giving eight across two bars.'),
        item('A three-bar 4/4 pattern has how many quarter-note beats in total?', ['Six', 'Nine', 'Twelve', 'Sixteen'], 2, 'Three bars of four quarter-note beats give twelve beats.'),
        item('One bar of 4/4 contains only three quarter-note beats so far. What completes it?', ['One quarter rest', 'A whole note', 'Three half notes', 'Nothing'], 0, 'A one-beat quarter rest brings the bar total to four.'),
        METER, 'Bars and time signatures', 'Open Music Theory'),
    skill('practice', 'Practise one clear target', 'Choose accuracy before increasing speed.',
        'Set a small observable target, such as keeping a pattern even for two repetitions. Choose a speed at which you can do that comfortably. Isolate the difficult section and repeat it before joining the full phrase. A slower clean version is useful evidence.',
        'Target: two even repetitions\nObserve: where did the pulse change?\nAdjust: slow down and isolate that point',
        'Try your two-bar pattern twice. Record one specific difficulty and one change you made. The app does not listen or automatically score your performance.',
        item('A pattern becomes uneven at a fast tempo. What is a useful next practice step?', ['Speed up again', 'Slow down and isolate the difficult part', 'Ignore timing', 'Only increase volume'], 1, 'A slower focused repetition makes the source of the difficulty easier to notice.'),
        item('Which practice goal is easiest to check?', ['Become amazing today', 'Be more musical', 'Keep four bars even for two repetitions', 'Never make a mistake again'], 2, 'A short observable target gives you something concrete to compare.'),
        item('What best supports a useful practice reflection?', ['A specific observation about one attempt', 'Only a streak number', 'An unexplained grade', 'The fastest possible tempo'], 0, 'A specific observation suggests a practical next adjustment.'),
        PRACTICE, 'Counting and practice examples', 'Open Music Theory'),
    skill('create', 'Make and review your own idea', 'Combine pulse, length, and reflection.',
        'Make a short original pattern using ideas you can explain. Count each bar, perform it twice, and compare the attempts. A recording can help you notice timing, but the review is yours: this prototype does not judge audio or musical expression.',
        'Create → count → perform → compare → change one thing',
        'Make an original four-bar rhythm, mark one rest, and write a two-sentence review of its timing. Use paper, clapping, or an instrument.',
        item('Which check is most useful before performing a new 4/4 rhythm?', ['Its title has four words', 'Every bar totals four quarter-note beats', 'Every sound is loud', 'There are no rests'], 1, 'Checking each bar’s duration helps verify that the written rhythm fits its meter.'),
        item('Your second attempt is steadier after slowing down. What can you conclude?', ['You have mastered all music', 'This adjustment helped this attempt', 'Speed no longer matters anywhere', 'No further practice is useful'], 1, 'This is evidence about a specific attempt, not proof of general mastery.'),
        item('Which review leads most directly to a next action?', ['It was bad', 'I am done forever', 'Bar three rushed; repeat it more slowly', 'The file name is long'], 2, 'It identifies a location, an observable issue, and a concrete practice step.'),
        PRACTICE, 'Applying and reviewing musical patterns', 'Open Music Theory'),
]

CLOTHING = 'https://pubs.nmsu.edu/_c/index.html'
QUALITY = 'https://pubs.nmsu.edu/_c/C103.pdf'
fashion = [
    skill('brief', 'Turn an idea into a brief', 'Name the wearer, use, and design intention.',
        'A design brief connects appearance to use. Describe who the item is for, when it will be used, and two useful constraints. Sketch the overall silhouette and label the features that serve your intention. A beautiful detail still needs a reason within the design.',
        'Use: everyday carry\nNeeds: easy opening + durable edge\nSketch: shape, opening, and construction notes',
        'Write a three-line brief for an accessory or garment of your choice. Sketch its front and label two features.',
        item('Which detail belongs in a useful design brief?', ['Only the designer’s favourite color', 'Intended use and wearer’s needs', 'Only a brand name', 'A final price without context'], 1, 'Use and wearer needs give the design decisions a clear purpose.'),
        item('A bag is intended for carrying sketchbooks. What should guide its dimensions?', ['The sketchbooks and how it will be carried', 'A random number', 'Only the thread color', 'The date'], 0, 'The intended contents and use should inform the design dimensions.'),
        item('Which sketch note best connects a feature to its purpose?', ['Add something nice', 'A wider opening lets the notebook slide in', 'Make every detail larger', 'No labels are needed'], 1, 'It explains why a feature is included and what it should achieve.'),
        CLOTHING, 'Clothing design, selection, and construction resources', 'NMSU Extension'),
    skill('fabric', 'Understand your material', 'Notice structure, stretch, and grain.',
        'Fabric choice changes how an item hangs and holds a seam. Compare the stretch and feel of a woven and a knit if you have scraps. On woven fabric, the lengthwise grain runs parallel to the selvage. Follow a pattern’s grainline and fabric recommendations rather than treating every material alike.',
        'Woven fabric: selvage ║ lengthwise grain\nCompare: stretch, thickness, drape, fraying',
        'Compare two fabric scraps or written fabric descriptions. Record stretch, thickness, and whether the edge frays. Explain which suits your brief.',
        item('On a woven fabric, the lengthwise grain generally runs…', ['Diagonally to the selvage', 'Parallel to the selvage', 'Only around a curved edge', 'In no direction'], 1, 'The lengthwise grain follows the warp direction, parallel to the selvage.'),
        item('A pattern recommends a stretch knit. What should you check before substituting fabric?', ['Only its color', 'Its price tag font', 'Its stretch and behavior', 'Only its packaging'], 2, 'Changing stretch can change fit and construction, even when colors match.'),
        item('Which comparison is useful when choosing fabric for a structured item?', ['Only the shop name', 'Drape, thickness, and stability', 'Only the roll length', 'Only the label color'], 1, 'These properties affect how the item holds its shape and can be constructed.'),
        CLOTHING, 'Fabric selection and textile resources', 'NMSU Extension'),
    skill('measure', 'Measure with a clear record', 'Use consistent units and repeat checks.',
        'Record what was measured, the units, and any intended ease or allowance separately. Repeat a measurement before cutting. A measurement is not a pattern size by itself; compare it with the specific pattern’s sizing information. For this demo, practise on paper or an object rather than entering personal body measurements.',
        'Object width: 12 cm\nObject height: 18 cm\nAllowances: recorded separately',
        'Measure a notebook or paper rectangle twice. Label width, height, and units. Compare the two readings before planning a pattern.',
        item('Which measurement record is clearest?', ['Width: 12', 'Width: 12 cm', 'Something about 12', 'Size: nice'], 1, 'A named dimension and unit make the record usable and repeatable.'),
        item('One measurement is in inches and another in centimeters. What should you do before comparing?', ['Assume they match', 'Choose the bigger numeral', 'Convert to the same unit', 'Ignore both labels'], 2, 'A common unit is needed for a meaningful numerical comparison.'),
        item('Your two width measurements differ. What is a useful next step?', ['Cut immediately', 'Average without checking', 'Remeasure with a consistent method', 'Remove the unit'], 2, 'Checking the method and repeating the measurement can reveal the source of the difference.'),
        CLOTHING, 'Measurement and pattern-fit guides', 'NMSU Extension'),
    skill('pattern', 'Separate stitching from cutting', 'Add the specified seam allowance.',
        'A stitch line marks where pieces join. A cut line may include extra fabric outside it. That extra width is the seam allowance. Follow the allowance stated by the pattern; not every pattern uses the same value. Practise with a paper rectangle before using fabric.',
        'Finished rectangle: 8 × 10 cm\nAllowance: 1 cm on every edge\nCut rectangle: 10 × 12 cm',
        'Draw an 8 × 10 cm finished rectangle on paper. Add a separate 1 cm seam allowance on every edge, then label both lines.',
        item('What is a seam allowance?', ['Extra fabric between stitch line and cut edge', 'Only a decorative line', 'The whole garment width', 'A universal pattern size'], 0, 'It is the width provided outside the stitching line to construct the seam.'),
        item('A finished width is 12 cm with 1 cm allowance on each side. What is the cut width?', ['12 cm', '13 cm', '14 cm', '24 cm'], 2, 'Add one centimeter on the left and one on the right: fourteen centimeters.'),
        item('A finished width is 8 cm with 1 cm allowance at both sides. What is the cut width?', ['8 cm', '9 cm', '10 cm', '12 cm'], 2, 'The two allowances add two centimeters to the finished width.'),
        CLOTHING, 'Pattern and construction guidance', 'NMSU Extension'),
    skill('seam', 'Make a controlled sample seam', 'Test the join before the final piece.',
        'A sample lets you check alignment, seam width, and stitch quality before joining the final pieces. Mark the intended seam line and keep the allowance consistent. Begin with a paper mockup, or use a scrap sample with equipment you know how to operate according to its instructions.',
        'Align edges → mark seam line → join sample → check width and puckering',
        'Make a paper mockup or a small scrap seam sample. Mark the seam line and inspect whether its width stays consistent. A photograph or written observation is for your own review; this app does not inspect it.',
        item('Why make a seam sample on scrap first?', ['To skip checking fit forever', 'To test the join and settings before final fabric', 'To remove all seam allowance', 'To hide the stitch line'], 1, 'A sample helps reveal construction problems before using the final pieces.'),
        item('A seam sample puckers. What is a sensible next step?', ['Use it on every final piece anyway', 'Check fabric handling and stitch settings on another scrap', 'Cut away the whole allowance', 'Stop recording observations'], 1, 'A controlled scrap test helps identify and adjust the cause before final construction.'),
        item('Which observation is most useful when reviewing a sample seam?', ['The allowance stays near the marked width', 'The scrap has a long name', 'The spool is new', 'The scissors have a logo'], 0, 'It checks a feature of the actual seam against the intended construction.'),
        QUALITY, 'Construction quality review checklist', 'NMSU Extension'),
    skill('finish', 'Finish, inspect, and refine', 'Review the result against the brief.',
        'Choose an edge finish that suits the material and use. Check for loose stitches, fraying, and uneven edges. Pressing and care depend on the fabric, so use its care instructions and test scraps first. Finally compare the item or mockup with your original brief and name one improvement.',
        'Review: function + dimensions + secure join + clean edge\nImprove: one observable change at a time',
        'Review your paper mockup or sewn sample against the brief. Note one thing that works and one concrete change. Completing this task is self-reported, not a professional construction grade.',
        item('What should guide an edge finish?', ['Only which method is fastest', 'The fabric, construction, and intended use', 'A random seam width', 'Only the date'], 1, 'The material and intended use influence a suitable finish.'),
        item('Which final review best checks the design intention?', ['Compare the item with the original brief and observed use', 'Only count the tools', 'Ignore the sample', 'Remove all labels'], 0, 'The brief provides concrete intentions against which you can review the result.'),
        item('Which note provides a useful next alteration?', ['Make it better somehow', 'Everything is mastered', 'The opening is too narrow for the notebook; widen the mockup', 'The project title is short'], 2, 'It identifies an observed problem and a specific change to test.'),
        QUALITY, 'Reviewing a clothing project', 'NMSU Extension'),
]

def build(identifier, title, description, hint, project, rows):
    questions, recall, resources, skills = [], [], [], []
    previous = []
    for row in rows:
        key = f"{identifier}-{row['key']}"
        resource_id = f'{key}-reference'
        for destination, kind in [(questions, 'baseline'), (recall, 'recall')]:
            q = dict(row[kind])
            q.update(id=f'{key}-{kind}', skill=key, label=row['title'], resource_id=resource_id)
            destination.append(q)
        lesson = dict(row['practice'])
        lesson.update(idea=row['subtitle'], body=row['body'], example=row['example'], task=row['task'])
        skills.append(dict(id=key, title=row['title'], subtitle=row['subtitle'],
            prerequisites=list(previous[-1:]), minutes=15, deliverable=row['task'],
            resource_id=resource_id, lesson=lesson))
        resources.append(dict(id=resource_id, title=row['resource_title'], publisher=row['publisher'],
            url=row['url'], skill=key, format='Reference', description='A publisher reference to explore alongside this original Sumi exercise.', level='Foundations', minutes=10))
        previous.append(key)
    return dict(id=identifier, title=title, description=description, goal_hint=hint,
        project=project, questions=questions, recall_questions=recall,
        skills=skills, resources=resources, calibration=CALIBRATION)

tracks = [
    build('music', 'Music', 'A starter check of basic Western rhythm, pitch vocabulary, and practice planning. This version does not listen to or grade audio.',
        'What would you like to play, create, or understand?',
        'An original short rhythm pattern, with counted bars and your own performance review.', music),
    build('fashion', 'Fashion Design & Tailoring', 'A starter check of design briefs, fabrics, measurement, patterns, sample seams, and quality review. Practical work is self-reported.',
        'What would you like to design or make?',
        'A labelled design brief and paper mockup or scrap sample, reviewed against your chosen purpose.', fashion),
]
(ROOT / 'app/assets/disciplines.json').write_text(json.dumps({'tracks': tracks}, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print('Created Music and Fashion Design & Tailoring demo tracks, with separate baseline, practice, and follow-up questions.')
