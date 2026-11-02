import json, re, csv, math, os, collections, unicodedata
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
CAT=ROOT/'supabase/catalog'
existing=json.loads((CAT/'recipes.json').read_text())['recipes']
units=json.loads((CAT/'ingredients.json').read_text())
# Estimate RD$ per canonical gram, milliliter, or piece. Not checkout/package pricing.
rates={'oats':.18,'milk':.085,'banana':13,'walnuts':1.6,'cinnamon':1.2,'bread':.20,'avocado':65,'eggs':10,'tomatoes':.12,'oliveOil':1.15,'salt':.12,'pepper':2.1,'yogurt':.42,'mango':55,'strawberries':.68,'granola':.47,'salmon':1.75,'potatoes':.105,'broccoli':.30,'lemon':16,'herbs':1.3,'chicken':.46,'rice':.082,'carrot':.09,'garlic':.40,'chickpeas':.22,'cucumber':.15,'onion':.125,'pasta':.13,'basil':2,'cheese':.75,'sweetPotato':.14,'spinach':.33,'lentils':.21,'celery':.18,'vegetableStock':.055,'apple':32,'peanutButter':.9,'tortilla':22,'blackBeans':.18,'tuna':.84,'groundBeef':.70,'bellPepper':.22,'mushrooms':.68,'zucchini':.24,'pineapple':.18,'tofu':.75,'quinoa':.48}
assert set(rates)==set(units)
labels={
'oats':('avena','oats'),'milk':('leche','milk'),'banana':('banana','banana'),'walnuts':('nueces','walnuts'),'cinnamon':('canela','cinnamon'),'bread':('pan','bread'),'avocado':('aguacate','avocado'),'eggs':('huevos','eggs'),'tomatoes':('tomate','tomatoes'),'oliveOil':('aceite de oliva','olive oil'),'salt':('sal','salt'),'pepper':('pimienta','pepper'),'yogurt':('yogur natural','plain yogurt'),'mango':('mango','mango'),'strawberries':('fresas','strawberries'),'granola':('granola','granola'),'salmon':('salmón','salmon'),'potatoes':('papa','potatoes'),'broccoli':('brócoli','broccoli'),'lemon':('limón','lemon'),'herbs':('hierbas frescas','fresh herbs'),'chicken':('pechuga de pollo','chicken breast'),'rice':('arroz crudo','dry rice'),'carrot':('zanahoria','carrot'),'garlic':('ajo','garlic'),'chickpeas':('garbanzos cocidos','cooked chickpeas'),'cucumber':('pepino','cucumber'),'onion':('cebolla','onion'),'pasta':('pasta seca','dry pasta'),'basil':('albahaca','basil'),'cheese':('queso','cheese'),'sweetPotato':('batata','sweet potato'),'spinach':('espinaca','spinach'),'lentils':('lentejas cocidas','cooked lentils'),'celery':('apio','celery'),'vegetableStock':('caldo de vegetales','vegetable broth'),'apple':('manzana','apple'),'peanutButter':('mantequilla de maní','peanut butter'),'tortilla':('tortilla de trigo','wheat tortilla'),'blackBeans':('habichuelas negras cocidas','cooked black beans'),'tuna':('atún escurrido','drained tuna'),'groundBeef':('carne molida','ground beef'),'bellPepper':('pimiento','bell pepper'),'mushrooms':('champiñones','mushrooms'),'zucchini':('calabacín','zucchini'),'pineapple':('piña','pineapple'),'tofu':('tofu firme','firm tofu'),'quinoa':('quinoa cruda','dry quinoa')}
# Nutrients per 100g or 100ml, pieces handled by representative gram equivalent.
nutr={'oats':(389,16.9,66.3,6.9),'milk':(61,3.2,4.8,3.3),'banana':(89,1.1,22.8,.3),'walnuts':(654,15.2,13.7,65.2),'cinnamon':(247,4,81,1.2),'bread':(265,9,49,3.2),'avocado':(160,2,8.5,14.7),'eggs':(143,12.6,.7,9.5),'tomatoes':(18,.9,3.9,.2),'oliveOil':(884,0,0,100),'salt':(0,0,0,0),'pepper':(251,10,64,3.3),'yogurt':(61,3.5,4.7,3.3),'mango':(60,.8,15,.4),'strawberries':(32,.7,7.7,.3),'granola':(460,10,65,17),'salmon':(208,20,0,13),'potatoes':(77,2,17,.1),'broccoli':(34,2.8,7,.4),'lemon':(29,1.1,9.3,.3),'herbs':(35,3,6,.5),'chicken':(120,22.5,0,2.6),'rice':(365,7.1,80,.7),'carrot':(41,.9,9.6,.2),'garlic':(149,6.4,33,.5),'chickpeas':(164,8.9,27.4,2.6),'cucumber':(15,.7,3.6,.1),'onion':(40,1.1,9.3,.1),'pasta':(371,13,74,1.5),'basil':(23,3.2,2.7,.6),'cheese':(300,22,3,23),'sweetPotato':(86,1.6,20.1,.1),'spinach':(23,2.9,3.6,.4),'lentils':(116,9,20,.4),'celery':(16,.7,3,.2),'vegetableStock':(6,.3,1,.2),'apple':(52,.3,13.8,.2),'peanutButter':(590,25,20,50),'tortilla':(306,8,52,7.6),'blackBeans':(132,8.9,23.7,.5),'tuna':(116,25.5,0,.8),'groundBeef':(170,20,0,9),'bellPepper':(31,1,6,.3),'mushrooms':(22,3.1,3.3,.3),'zucchini':(17,1.2,3.1,.3),'pineapple':(50,.5,13,.1),'tofu':(110,12,3,6),'quinoa':(368,14.1,64.2,6.1)}
piece_g={'banana':120,'avocado':140,'eggs':50,'mango':200,'lemon':60,'apple':180,'tortilla':50}
assert set(nutr)==set(units)

def parse(s):
 out={}
 for bit in s.split(','):
  bit=bit.strip()
  if not bit: continue
  k,v=bit.split(':')
  assert k in units,(k,s)
  out[k]=float(v)
 return out

def money(n): return round(n+1e-7,2)

def price_rows(amounts):
 lines=[]; total=0
 for a in amounts:
  amount=float(a['amount']); rate=rates[a['ingredient']]
  if a['unit']=='pieces' and units[a['ingredient']]=='grams':
   rate=round(rate*float(a['grams_per_piece']),3)
  cents=max(1,int(math.floor(amount*rate*100+0.50000001)));total+=cents
  lines.append({'ingredient':a['ingredient'],'amount':amount,'unit':a['unit'],'unit_price_dop':rate,'estimated_total_cents':cents})
 return {'currency':'DOP','method':'ingredient_portion_estimate','market':'DO','as_of':'2026-11-01','estimated':True,'total_cents':total,'per_serving_cents':None,'lines':lines}

def nutrition_calc(amounts,servings):
 sums=[0.0]*4
 for a in amounts:
  i=a['ingredient']; q=a['amount']; mass=q if a['unit']=='grams' else (q if a['unit']=='milliliters' else q*piece_g[i])
  if i=='oliveOil': mass=mass*.91
  for j,n in enumerate(nutr[i]): sums[j]+=n*mass/100
 return {'calories':int(round(sums[0]/servings)),'protein_grams':int(round(sums[1]/servings)),'carbs_grams':int(round(sums[2]/servings)),'fat_grams':int(round(sums[3]/servings)),'estimated':True}

def qty(a,lang):
 q=a['amount']; k=a['ingredient']; unit=a['unit']
 if unit=='grams': return f'{q:g} g de {labels[k][0]}' if lang=='es' else f'{q:g} g {labels[k][1]}'
 if unit=='milliliters': return f'{q:g} ml de {labels[k][0]}' if lang=='es' else f'{q:g} ml {labels[k][1]}'
 return f'{q:g} unidad(es) de {labels[k][0]}' if lang=='es' else f'{q:g} {labels[k][1]} (pieces)'

def slug(s):
 s=unicodedata.normalize('NFKD',s.lower()).encode('ascii','ignore').decode();return re.sub(r'-+','-',re.sub('[^a-z0-9]+','-',s)).strip('-')

def split_variant(raw):
 a=raw.split('|')
 assert len(a)==3,raw
 return a[0].strip(),a[1].strip(),parse(a[2].strip())

# Each family has base ingredients and culinary technique (Spanish and English).
# Variant ingredients change protein/grains/vegetables/toppings per named recipe.
F=[]
def group(slot,kind,base,desc_es,desc_en,steps_es,steps_en,lines):
 variants=[split_variant(x.strip()) for x in lines.strip().split('\n') if x.strip()]
 F.append(dict(slot=slot,kind=kind,base=parse(base),desc_es=desc_es,desc_en=desc_en,steps_es=steps_es,steps_en=steps_en,variants=variants))

# 60 breakfast recipes = 10 families x 6.
group('breakfast','porridge','oats:90,milk:380,cinnamon:1', 'Un desayuno caliente, cremoso y fácil de preparar.', 'A warm, creamy, easy-to-make breakfast.',
 ['Pon la avena y la leche en una olla; cocina a fuego suave de 6 a 8 minutos, removiendo.', 'Prepara la fruta y los complementos indicados; incorpóralos según su textura, dejando los crujientes para el final.', 'Reparte en dos platos y sirve caliente; ajusta el espesor con un poco de agua si hace falta.'],
 ['Simmer oats and milk gently for 6–8 minutes, stirring often.', 'Prepare the listed fruit and extras; stir soft additions into the oats and reserve crunchy ones for topping.', 'Divide between two bowls and serve warm; loosen with a little water if needed.'], '''Avena con manzana, nueces y canela|Apple walnut cinnamon oatmeal|apple:1,walnuts:22
Avena de mango y granola|Mango granola oatmeal|mango:1,granola:45
Avena con fresas y crema de maní|Strawberry peanut butter oatmeal|strawberries:140,peanutButter:25
Avena con banana y piña|Banana pineapple oatmeal|banana:1,pineapple:140
Avena con manzana y yogur|Apple yogurt oatmeal|apple:1,yogurt:130
Avena con mango y nueces|Mango walnut oatmeal|mango:1,walnuts:25''')
group('breakfast','overnight','oats:90,milk:250,yogurt:160', 'Avena reposada en frío, ideal para dejar lista la noche anterior.', 'Chilled oats prepared the night before.',
 ['Mezcla la avena, la leche y el yogur en un recipiente limpio.', 'Incorpora la fruta lavada o troceada y los complementos; reserva la granola si la usas.', 'Tapa y refrigera al menos 6 horas. Divide en dos porciones, añade los complementos crujientes y sirve fría.'],
 ['Mix oats, milk and yogurt in a clean container.', 'Fold in washed or chopped fruit and other additions; reserve granola if using.', 'Cover and refrigerate at least 6 hours; divide into two portions, add crunchy toppings and serve cold.'], '''Avena nocturna de fresa y banana|Strawberry banana overnight oats|strawberries:120,banana:1
Avena nocturna de manzana y canela|Apple cinnamon overnight oats|apple:1,cinnamon:2
Avena nocturna de mango y piña|Mango pineapple overnight oats|mango:1,pineapple:120
Avena nocturna con mantequilla de maní y banana|Peanut banana overnight oats|peanutButter:30,banana:1
Avena nocturna de fresa y nueces|Strawberry walnut overnight oats|strawberries:150,walnuts:20
Avena nocturna de manzana y granola|Apple granola overnight oats|apple:1,granola:40''')
group('breakfast','yogurt','yogurt:300,granola:40','Un bowl fresco con fruta y texturas variadas.','A fresh fruit bowl with satisfying textures.',
 ['Lava y corta la fruta que requiera preparación.', 'Reparte el yogur en dos bowls y agrega las frutas y otros ingredientes indicados.', 'Termina con granola o frutos secos justo antes de comer para conservar su textura.'],
 ['Wash and cut any fruit as needed.', 'Divide yogurt between two bowls, then add fruit and the other listed ingredients.', 'Finish with granola or nuts just before serving so they stay crunchy.'], '''Yogur con mango y banana|Mango banana yogurt bowl|mango:1,banana:1
Yogur con manzana y canela|Apple cinnamon yogurt bowl|apple:1,cinnamon:2
Yogur con fresa y nueces|Strawberry walnut yogurt bowl|strawberries:200,walnuts:24
Yogur tropical de piña y mango|Pineapple mango yogurt bowl|pineapple:170,mango:1
Yogur con banana y mantequilla de maní|Peanut banana yogurt bowl|banana:1,peanutButter:32
Yogur de fresa, piña y nueces|Strawberry pineapple walnut yogurt bowl|strawberries:110,pineapple:110,walnuts:20''')
group('breakfast','smoothie','milk:330,yogurt:130','Batido espeso hecho con fruta real, sin azúcar añadida.','A thick fruit smoothie with no added sugar.',
 ['Lava y corta la fruta; retira semillas o cáscaras no comestibles.', 'Licúa la leche y el yogur con la fruta y los ingredientes indicados hasta obtener una mezcla uniforme.', 'Sirve en dos vasos; agrega agua o hielo si quieres una textura más ligera.'],
 ['Wash and trim the fruit, removing inedible seeds or skins.', 'Blend milk and yogurt with the fruit and listed additions until smooth.', 'Pour into two glasses; add water or ice for a lighter consistency.'], '''Batido de mango, avena y yogur|Mango oat yogurt smoothie|mango:1,oats:45
Batido de banana y maní|Peanut banana smoothie|banana:2,peanutButter:28
Batido de fresa y banana|Strawberry banana smoothie|strawberries:190,banana:1
Batido verde de piña y espinaca|Pineapple spinach smoothie|pineapple:200,spinach:45
Batido de manzana y canela|Apple cinnamon smoothie|apple:2,cinnamon:2
Batido tropical de mango y piña|Mango pineapple smoothie|mango:1,pineapple:180''')
group('breakfast','scramble','eggs:4,oliveOil:8,salt:2','Huevos revueltos con vegetales para una mañana completa.','Soft scrambled eggs with vegetables.',
 ['Lava y pica los vegetales; bate los huevos con la sal.', 'Calienta el aceite en una sartén y saltea primero los vegetales más firmes hasta ablandarlos.', 'Añade los huevos y remueve a fuego bajo hasta que cuajen por completo; sirve en dos platos.'],
 ['Wash and chop the vegetables, then beat the eggs with salt.', 'Warm oil in a skillet and sauté firmer vegetables until softened.', 'Add beaten eggs and stir gently over low heat until fully set; divide into two plates.'], '''Revoltillo de tomate y espinaca|Tomato spinach scrambled eggs|tomatoes:170,spinach:80
Revoltillo de champiñones y cebolla|Mushroom onion scrambled eggs|mushrooms:150,onion:90
Revoltillo de brócoli y queso|Broccoli cheese scrambled eggs|broccoli:130,cheese:55
Revoltillo de pimiento y tomate|Pepper tomato scrambled eggs|bellPepper:125,tomatoes:135
Revoltillo de calabacín y hierbas|Zucchini herb scrambled eggs|zucchini:180,herbs:8
Revoltillo de espinaca y habichuelas negras|Spinach black bean scrambled eggs|spinach:80,blackBeans:125''')
group('breakfast','omelette','eggs:4,oliveOil:8,salt:2','Tortilla de huevos tierna y dorada con un relleno sabroso.','A tender golden omelet with a savory filling.',
 ['Pica los vegetales y saltea en una sartén antiadherente con la mitad del aceite.', 'Bate los huevos con la sal y vierte sobre los vegetales; cocina a fuego medio-bajo.', 'Cuando el centro esté casi firme, agrega los ingredientes restantes, dobla la tortilla y termina la cocción antes de dividir.'],
 ['Chop and sauté vegetables in a nonstick pan with half the oil.', 'Beat eggs with salt and pour over the vegetables; cook over medium-low heat.', 'When nearly set, add remaining ingredients, fold the omelet, and cook through before dividing.'], '''Omelette de espinaca, champiñones y queso|Spinach mushroom cheese omelet|spinach:100,cheese:50,mushrooms:105
Omelette de tomate y albahaca|Tomato basil omelet|tomatoes:160,basil:9
Omelette de champiñones y brócoli|Mushroom broccoli omelet|mushrooms:125,broccoli:100
Omelette de pimiento y cebolla|Pepper onion omelet|bellPepper:130,onion:100
Omelette de calabacín y queso|Zucchini cheese omelet|zucchini:170,cheese:45
Omelette de aguacate y tomate|Avocado tomato omelet|avocado:1,tomatoes:110''')
group('breakfast','toast','bread:120,oliveOil:5','Tostadas crujientes con toppings sencillos.','Crisp toast with simple toppings.',
 ['Tuesta el pan en una sartén seca o tostadora hasta que quede dorado.', 'Prepara los complementos: cocina por completo los huevos si los hay y corta los vegetales o frutas.', 'Distribuye las coberturas en las tostadas, agrega el aceite cuando corresponda y sirve de inmediato.'],
 ['Toast the bread in a dry skillet or toaster until golden.', 'Prepare toppings: fully cook any eggs and slice fruit or vegetables.', 'Layer toppings on the toast, add the oil as appropriate, and serve promptly.'], '''Tostadas de aguacate, huevo y tomate|Avocado egg tomato toast|avocado:1,eggs:2,tomatoes:100
Tostadas de atún y tomate|Tuna tomato toast|tuna:140,tomatoes:130
Tostadas con manzana y mantequilla de maní|Apple peanut toast|apple:1,peanutButter:35
Tostadas de queso y champiñones|Cheesy mushroom toast|cheese:75,mushrooms:130
Tostadas de huevo y espinaca|Egg spinach toast|eggs:3,spinach:65
Tostadas de tomate y albahaca|Tomato basil toast|tomatoes:190,basil:10''')
group('breakfast','sandwich','bread:160','Sándwich recién hecho con ingredientes accesibles.','A freshly prepared everyday sandwich.',
 ['Prepara el relleno: lava los vegetales y cocina por completo las proteínas o los huevos cuando corresponda.', 'Tuesta ligeramente el pan; coloca los ingredientes uniformemente entre las rebanadas.', 'Corta en dos sándwiches y sirve de inmediato.'],
 ['Prepare the filling: wash vegetables and fully cook any eggs or proteins as needed.', 'Lightly toast the bread and distribute the fillings evenly between slices.', 'Cut into two sandwiches and serve immediately.'], '''Sándwich de huevo y tomate|Egg tomato sandwich|eggs:3,tomatoes:150
Sándwich de pollo y aguacate|Chicken avocado sandwich|chicken:180,avocado:1
Sándwich de atún y pepino|Tuna cucumber sandwich|tuna:150,cucumber:140
Sándwich de queso y espinaca|Cheese spinach sandwich|cheese:85,spinach:60
Sándwich de huevo y pimiento|Egg pepper sandwich|eggs:3,bellPepper:120
Sándwich de garbanzos y tomate|Chickpea tomato sandwich|chickpeas:185,tomatoes:120''')
group('breakfast','hash','potatoes:360,oliveOil:13,onion:80,salt:3','Salteado de papa con vegetales y proteína.','A hearty potato hash with vegetables and protein.',
 ['Corta la papa en cubos pequeños y hiérvela 7–10 minutos para empezar a ablandarla.', 'Saltea cebolla y los demás vegetales con aceite; añade las papas escurridas y dóralas.', 'Incorpora la proteína indicada, ya bien cocida si es carne o pollo; termina de cocinar los huevos si aparecen y reparte en dos porciones.'],
 ['Dice the potatoes and parboil them for 7–10 minutes.', 'Sauté onion and vegetables in oil; add drained potatoes and brown.', 'Add the listed protein, fully cooked if meat or poultry; cook any eggs until set and divide into two servings.'], '''Papas salteadas con huevo y espinaca|Egg spinach potato hash|eggs:3,spinach:80
Papas salteadas con pollo y pimiento|Chicken pepper potato hash|chicken:180,bellPepper:130
Papas salteadas con carne y tomate|Beef tomato potato hash|groundBeef:180,tomatoes:150
Papas salteadas con champiñones y queso|Mushroom cheese potato hash|mushrooms:150,cheese:50
Papas salteadas con brócoli y huevo|Broccoli egg potato hash|broccoli:140,eggs:3
Papas salteadas con habichuelas negras|Black bean potato hash|blackBeans:190,bellPepper:110''')
group('breakfast','quesadilla','tortilla:2,cheese:70','Quesadilla dorada con relleno casero.','A golden quesadilla with a homemade filling.',
 ['Prepara y pica los rellenos; cocina por completo las carnes o los huevos y saltea los vegetales húmedos.', 'Reparte el queso y los rellenos entre las tortillas y dóblalas.', 'Dora en sartén a fuego medio por ambos lados hasta que el queso funda; corta y sirve.'],
 ['Prepare and chop fillings; fully cook meat or eggs and sauté watery vegetables.', 'Divide cheese and fillings between tortillas and fold.', 'Toast on both sides in a medium-hot skillet until cheese melts, then slice and serve.'], '''Quesadilla de espinaca y tomate|Spinach tomato quesadilla|spinach:100,tomatoes:120
Quesadilla de huevo y pimiento|Egg pepper quesadilla|eggs:2,bellPepper:120
Quesadilla de champiñones y cebolla|Mushroom onion quesadilla|mushrooms:150,onion:80
Quesadilla de habichuelas negras|Black bean quesadilla|blackBeans:190,tomatoes:90
Quesadilla de pollo y espinaca|Chicken spinach quesadilla|chicken:180,spinach:90
Quesadilla de calabacín y hierbas|Zucchini herb quesadilla|zucchini:160,herbs:8''')

# 80 lunch recipes = 10 families x 8.
group('lunch','chicken-rice','rice:145,chicken:270,oliveOil:12,salt:3','Bowl completo de arroz con pollo y vegetales.','A satisfying rice, chicken and vegetable bowl.',
 ['Lava el arroz y cuécelo en agua hasta que esté tierno.', 'Corta el pollo en piezas y cocínalo completamente en una sartén con aceite; añade los vegetales más firmes primero.', 'Incorpora los vegetales restantes, condimenta con sal y reparte junto al arroz en dos bowls.'],
 ['Rinse and cook rice in water until tender.', 'Cut chicken into pieces and cook fully in a skillet with oil; add firmer vegetables first.', 'Add remaining vegetables, season with salt and serve alongside rice in two bowls.'], '''Bowl de pollo con brócoli y zanahoria|Chicken broccoli carrot rice bowl|broccoli:180,carrot:140
Bowl de pollo con pimiento y cebolla|Chicken pepper onion rice bowl|bellPepper:160,onion:100
Bowl de pollo con espinaca y tomate|Chicken spinach tomato rice bowl|spinach:110,tomatoes:180
Bowl de pollo con calabacín y ajo|Chicken zucchini garlic rice bowl|zucchini:210,garlic:11
Bowl de pollo con champiñones|Chicken mushroom rice bowl|mushrooms:180,onion:90
Bowl de pollo con piña y pimiento|Pineapple pepper chicken rice bowl|pineapple:140,bellPepper:130
Bowl de pollo con aguacate y tomate|Chicken avocado tomato rice bowl|avocado:1,tomatoes:160
Bowl de pollo con habichuelas negras|Chicken black bean rice bowl|blackBeans:190,bellPepper:100''')
group('lunch','tuna-grain','quinoa:125,tuna:200,oliveOil:9,lemon:1','Bowl fresco con cereal y atún, fácil de llevar.','A portable grain bowl with tuna.',
 ['Enjuaga la quinoa y cuécela en agua hasta que absorba el líquido; deja templar.', 'Escurre el atún y lava o corta los ingredientes frescos.', 'Mezcla todo con aceite y limón, reparte en dos porciones y sirve.'],
 ['Rinse quinoa and cook in water until the liquid is absorbed; let cool slightly.', 'Drain tuna and wash or chop fresh ingredients.', 'Toss with olive oil and lemon, divide into two portions and serve.'], '''Quinoa con atún, pepino y tomate|Tuna cucumber tomato quinoa|cucumber:150,tomatoes:180
Quinoa con atún y aguacate|Tuna avocado quinoa|avocado:1,tomatoes:140
Quinoa con atún y espinaca|Tuna spinach quinoa|spinach:110,carrot:100
Quinoa con atún, pimiento y cebolla|Tuna pepper onion quinoa|bellPepper:160,onion:80
Quinoa con atún y garbanzos|Tuna chickpea quinoa|chickpeas:170,cucumber:110
Quinoa con atún, brócoli y limón|Tuna broccoli lemon quinoa|broccoli:180,herbs:8
Quinoa con atún y champiñones|Tuna mushroom quinoa|mushrooms:160,onion:90
Quinoa tropical con atún y piña|Pineapple tuna quinoa|pineapple:180,cucumber:100''')
group('lunch','veggie-rice','rice:155,oliveOil:12,onion:85,garlic:8,salt:3','Arroz salteado con legumbres o vegetales.','A vegetable and bean rice skillet.',
 ['Cuece el arroz por separado y deja reposar unos minutos.', 'Sofríe la cebolla, el ajo y los vegetales con el aceite, hasta que estén tiernos.', 'Incorpora el arroz y las legumbres o proteínas indicadas; calienta todo y sirve en dos platos.'],
 ['Cook rice separately and allow it to rest briefly.', 'Sauté onion, garlic and vegetables in oil until tender.', 'Fold in rice and the listed beans or protein, heat through and divide into two plates.'], '''Arroz con habichuelas negras y pimiento|Black bean pepper rice|blackBeans:240,bellPepper:140
Arroz con garbanzos y zanahoria|Chickpea carrot rice|chickpeas:260,carrot:140
Arroz con tofu, brócoli y zanahoria|Tofu broccoli carrot rice|tofu:210,broccoli:170,carrot:110
Arroz con huevo y espinaca|Egg spinach rice|eggs:3,spinach:110
Arroz con lentejas y tomate|Lentil tomato rice|lentils:250,tomatoes:160
Arroz con champiñones y calabacín|Mushroom zucchini rice|mushrooms:160,zucchini:180
Arroz con atún y zanahoria|Tuna carrot rice|tuna:190,carrot:150
Arroz con pollo y vegetales verdes|Chicken green veggie rice|chicken:210,broccoli:140,spinach:80''')
group('lunch','pasta-salad','pasta:170,oliveOil:12,lemon:1','Ensalada de pasta fría con ingredientes frescos.','A chilled pasta salad with fresh ingredients.',
 ['Cuece la pasta al dente, escurre y enfría con agua potable.', 'Lava y corta los vegetales; escurre las conservas que lo requieran y cocina cualquier proteína cruda hasta su punto seguro.', 'Mezcla la pasta con todos los ingredientes, el aceite y el limón; enfría y sirve en dos porciones.'],
 ['Cook pasta until al dente, drain and cool with clean water.', 'Chop vegetables, drain canned foods, and fully cook any raw protein.', 'Toss pasta with all ingredients, oil and lemon; chill and divide into two servings.'], '''Ensalada de pasta con atún y pepino|Tuna cucumber pasta salad|tuna:200,cucumber:150
Ensalada de pasta con pollo y tomate|Chicken tomato pasta salad|chicken:230,tomatoes:170
Ensalada de pasta con garbanzos|Chickpea pasta salad|chickpeas:240,bellPepper:140
Ensalada de pasta con queso y albahaca|Cheese basil pasta salad|cheese:90,tomatoes:180,basil:9
Ensalada de pasta con brócoli|Broccoli pasta salad|broccoli:210,carrot:130
Ensalada de pasta con espinaca y champiñones|Spinach mushroom pasta salad|spinach:130,mushrooms:155
Ensalada de pasta con aguacate y tomate|Avocado tomato pasta salad|avocado:1,tomatoes:180
Ensalada tropical de pasta con piña y pollo|Pineapple chicken pasta salad|pineapple:180,chicken:220''')
group('lunch','pasta-skillet','pasta:180,tomatoes:240,oliveOil:12,garlic:9,salt:3','Pasta caliente con salsa de tomate casera.','Warm pasta with a simple tomato sauce.',
 ['Hierve la pasta en abundante agua hasta que quede al dente y reserva un poco del agua de cocción.', 'Sofríe el ajo con aceite, añade el tomate picado y cocina hasta formar una salsa; cocina por separado y por completo cualquier carne cruda.', 'Agrega los ingredientes restantes y la pasta; mezcla, ajusta la textura con agua de cocción y divide en dos platos.'],
 ['Boil pasta until al dente, reserving a little cooking water.', 'Sauté garlic in oil, add chopped tomato and cook into a sauce; fully cook any raw meat separately.', 'Add remaining ingredients and pasta; toss, loosen with cooking water and divide into two plates.'], '''Pasta de pollo y espinaca|Chicken spinach tomato pasta|chicken:240,spinach:110
Pasta de atún y albahaca|Tuna basil tomato pasta|tuna:210,basil:12
Pasta de champiñones y queso|Mushroom cheese tomato pasta|mushrooms:175,cheese:70
Pasta con carne molida y pimiento|Ground beef pepper pasta|groundBeef:230,bellPepper:140
Pasta con garbanzos y espinaca|Chickpea spinach pasta|chickpeas:220,spinach:100
Pasta de calabacín y albahaca|Zucchini basil tomato pasta|zucchini:200,basil:12
Pasta con brócoli y pollo|Broccoli chicken tomato pasta|broccoli:175,chicken:230
Pasta con lentejas y zanahoria|Lentil carrot tomato pasta|lentils:260,carrot:130''')
group('lunch','chickpea-salad','chickpeas:330,oliveOil:13,lemon:1','Ensalada abundante con garbanzos y vegetales.','A filling chickpea and vegetable salad.',
 ['Enjuaga y escurre los garbanzos cocidos.', 'Lava, corta o cocina los acompañantes según corresponda; las verduras firmes se pueden saltear ligeramente.', 'Combina con aceite y limón, ajusta al gusto y reparte en dos porciones.'],
 ['Rinse and drain cooked chickpeas.', 'Wash, chop or cook accompanying ingredients as needed; firm vegetables may be lightly sautéed.', 'Toss everything with olive oil and lemon, adjust to taste and divide between two bowls.'], '''Ensalada de garbanzos con pepino y tomate|Chickpea cucumber tomato salad|cucumber:160,tomatoes:170
Ensalada de garbanzos con atún|Chickpea tuna salad|tuna:160,onion:70
Ensalada de garbanzos con aguacate|Chickpea avocado salad|avocado:1,tomatoes:150
Ensalada de garbanzos con espinaca|Chickpea spinach salad|spinach:130,bellPepper:120
Ensalada de garbanzos y quinoa|Chickpea quinoa salad|quinoa:100,cucumber:130
Ensalada de garbanzos y zanahoria|Chickpea carrot salad|carrot:170,herbs:8
Ensalada de garbanzos con brócoli|Chickpea broccoli salad|broccoli:200,garlic:8
Ensalada de garbanzos y queso|Chickpea cheese salad|cheese:85,tomatoes:150''')
group('lunch','lentil-bowl','lentils:370,oliveOil:12,onion:90,garlic:8','Bowl templado de lentejas con vegetales y complementos.','A warm lentil bowl with vegetables and extras.',
 ['Usa lentejas ya cocidas y escurridas; prepara los vegetales.', 'Sofríe la cebolla y el ajo con aceite, agrega los vegetales firmes y deja ablandar.', 'Incorpora las lentejas y los ingredientes restantes; calienta, ajusta la humedad con agua y sirve en dos bowls.'],
 ['Start with cooked, drained lentils and prepared vegetables.', 'Sauté onion and garlic in oil, add firmer vegetables and soften.', 'Stir in lentils and remaining ingredients, heat through, add water if needed and divide into two bowls.'], '''Lentejas con zanahoria y tomate|Carrot tomato lentil bowl|carrot:160,tomatoes:180
Lentejas con brócoli y espinaca|Broccoli spinach lentil bowl|broccoli:160,spinach:105
Lentejas con calabacín|Zucchini lentil bowl|zucchini:220,herbs:8
Lentejas con papa y zanahoria|Potato carrot lentil bowl|potatoes:270,carrot:120
Lentejas con quinoa y pimiento|Quinoa pepper lentil bowl|quinoa:110,bellPepper:130
Lentejas con arroz y tomate|Rice tomato lentil bowl|rice:115,tomatoes:160
Lentejas con tofu y brócoli|Tofu broccoli lentil bowl|tofu:210,broccoli:150
Lentejas con champiñones y espinaca|Mushroom spinach lentil bowl|mushrooms:165,spinach:95''')
group('lunch','wrap','tortilla:2,oliveOil:7','Wrap casero práctico para el almuerzo.','A practical homemade lunch wrap.',
 ['Lava los vegetales, escurre las legumbres y cocina bien las proteínas crudas.', 'Calienta ligeramente las tortillas y prepara el relleno con los ingredientes indicados.', 'Distribuye el relleno en las tortillas, enróllalas firmemente y sirve dos wraps.'],
 ['Wash vegetables, drain beans and fully cook raw proteins.', 'Warm tortillas gently and prepare the filling using all listed ingredients.', 'Divide filling between tortillas, roll tightly and serve two wraps.'], '''Wrap de pollo, aguacate y tomate|Chicken avocado tomato wrap|chicken:210,avocado:1,tomatoes:115
Wrap de atún y pepino|Tuna cucumber wrap|tuna:185,cucumber:140,yogurt:45
Wrap de garbanzos y espinaca|Chickpea spinach wrap|chickpeas:230,spinach:100,tomatoes:110
Wrap de carne molida y pimiento|Ground beef pepper wrap|groundBeef:210,bellPepper:130,onion:85
Wrap de huevo y queso|Egg cheese wrap|eggs:3,cheese:65,tomatoes:120
Wrap de habichuelas negras y aguacate|Black bean avocado wrap|blackBeans:240,avocado:1,tomatoes:100
Wrap de tofu y brócoli|Tofu broccoli wrap|tofu:220,broccoli:130,carrot:100
Wrap de pollo con champiñones|Chicken mushroom wrap|chicken:210,mushrooms:140,spinach:60''')
group('lunch','chicken-soup','chicken:240,vegetableStock:700,onion:80,garlic:8,salt:3','Sopa hogareña con pollo y vegetales.','A comforting chicken and vegetable soup.',
 ['Corta el pollo en trozos pequeños y prepara las verduras.', 'Lleva el caldo a hervor suave con cebolla y ajo; incorpora el pollo y los vegetales firmes.', 'Cocina hasta que el pollo esté completamente hecho y las verduras tiernas, añade los ingredientes delicados al final y divide en dos tazones.'],
 ['Cut chicken into small pieces and prep the vegetables.', 'Bring broth to a gentle simmer with onion and garlic; add chicken and firm vegetables.', 'Cook until chicken is fully done and vegetables tender; add delicate ingredients last and divide into two bowls.'], '''Sopa de pollo con papa y zanahoria|Chicken potato carrot soup|potatoes:240,carrot:145
Sopa de pollo con arroz y espinaca|Chicken rice spinach soup|rice:100,spinach:100
Sopa de pollo con brócoli|Chicken broccoli soup|broccoli:210,carrot:105
Sopa de pollo con lentejas|Chicken lentil soup|lentils:240,celery:90
Sopa de pollo con calabacín|Chicken zucchini soup|zucchini:220,tomatoes:120
Sopa de pollo con quinoa|Chicken quinoa soup|quinoa:90,spinach:80
Sopa de pollo con champiñones|Chicken mushroom soup|mushrooms:190,carrot:115
Sopa de pollo con garbanzos|Chicken chickpea soup|chickpeas:200,tomatoes:155''')
group('lunch','tofu-wok','tofu:290,oliveOil:14,garlic:10,onion:90','Salteado rápido de tofu y vegetales.','A quick tofu and vegetable stir-fry.',
 ['Seca el tofu y córtalo en cubos; lava y pica los vegetales.', 'Dora el tofu en aceite a fuego medio-alto; retira y saltea ajo, cebolla y los vegetales firmes.', 'Reincorpora el tofu y agrega los ingredientes restantes, cocina hasta ablandar y divide en dos porciones.'],
 ['Pat tofu dry and dice it; wash and chop vegetables.', 'Brown tofu in oil over medium-high heat; remove it and sauté garlic, onion and firm vegetables.', 'Return tofu, add remaining ingredients, cook until tender and divide into two servings.'], '''Tofu salteado con brócoli y zanahoria|Tofu broccoli carrot stir-fry|broccoli:220,carrot:160
Tofu salteado con pimiento y champiñones|Tofu pepper mushroom stir-fry|bellPepper:170,mushrooms:170
Tofu salteado con calabacín y tomate|Tofu zucchini tomato stir-fry|zucchini:220,tomatoes:160
Tofu salteado con arroz y espinaca|Tofu rice spinach stir-fry|rice:130,spinach:110
Tofu salteado con quinoa y brócoli|Tofu quinoa broccoli stir-fry|quinoa:115,broccoli:190
Tofu salteado con piña y pimiento|Tofu pineapple pepper stir-fry|pineapple:175,bellPepper:155
Tofu salteado con habichuelas negras|Tofu black bean stir-fry|blackBeans:200,carrot:110
Tofu salteado con papa y champiñones|Tofu potato mushroom stir-fry|potatoes:260,mushrooms:150''')

# 56 dinner recipes = 8 families x 7.
group('dinner','salmon-tray','salmon:290,oliveOil:13,lemon:1,salt:3','Salmón al horno acompañado de vegetales.','Oven-baked salmon with vegetables.',
 ['Calienta el horno a 200 °C; corta las verduras en piezas de tamaño similar.', 'Distribuye los vegetales y los ingredientes indicados en una bandeja con aceite; hornea primero los más duros si hace falta.', 'Añade el salmón y el limón; hornea hasta que el pescado esté bien cocido (63 °C en el centro), divide y sirve.'],
 ['Preheat the oven to 200°C/390°F; chop vegetables evenly.', 'Spread the vegetables and other listed additions on a tray with oil; start firmer vegetables earlier if needed.', 'Add salmon and lemon; bake until the fish reaches 63°C/145°F in the center, then divide and serve.'], '''Salmón al horno con papa y brócoli|Salmon potato broccoli traybake|potatoes:330,broccoli:200
Salmón al horno con batata y espinaca|Salmon sweet potato spinach traybake|sweetPotato:330,spinach:110
Salmón al horno con zanahoria y calabacín|Salmon carrot zucchini traybake|carrot:195,zucchini:190
Salmón al horno con quinoa y tomate|Salmon quinoa tomato traybake|quinoa:120,tomatoes:180
Salmón con champiñones y ajo|Salmon mushroom garlic traybake|mushrooms:215,garlic:10
Salmón con pimientos y cebolla|Salmon pepper onion traybake|bellPepper:210,onion:130
Salmón con brócoli y garbanzos|Salmon broccoli chickpea traybake|broccoli:175,chickpeas:220''')
group('dinner','beef-skillet','groundBeef:280,oliveOil:11,onion:90,garlic:9,salt:3','Sartén de carne molida con vegetales y una guarnición.','Ground beef skillet with vegetables and a side.',
 ['Corta la cebolla, el ajo y los vegetales; prepara la guarnición si la hay.', 'Sofríe la cebolla y el ajo con aceite; agrega la carne y cocínala completamente, desmenuzándola.', 'Incorpora verduras y legumbres según corresponda, cocina hasta ablandar y divide en dos platos.'],
 ['Chop onion, garlic and vegetables; prepare any grain or starchy side.', 'Sauté onion and garlic in oil; add beef and cook thoroughly, breaking it apart.', 'Add vegetables and beans as appropriate, cook until tender and divide into two plates.'], '''Carne molida con papa y zanahoria|Beef potato carrot skillet|potatoes:310,carrot:145
Carne molida con arroz y pimiento|Beef rice pepper skillet|rice:135,bellPepper:160
Carne molida con calabacín y tomate|Beef zucchini tomato skillet|zucchini:230,tomatoes:200
Carne molida con habichuelas negras|Beef black bean skillet|blackBeans:240,bellPepper:120
Carne molida con champiñones y espinaca|Beef mushroom spinach skillet|mushrooms:190,spinach:125
Carne molida con batata y brócoli|Beef sweet potato broccoli skillet|sweetPotato:300,broccoli:155
Carne molida con quinoa y tomate|Beef quinoa tomato skillet|quinoa:135,tomatoes:160''')
group('dinner','stuffed-pepper','bellPepper:330,tomatoes:125,oliveOil:10,onion:70','Pimientos rellenos y horneados hasta quedar tiernos.','Bell peppers stuffed and baked until tender.',
 ['Precalienta el horno a 190 °C; corta los pimientos por la mitad y retira las semillas.', 'Cocina por separado los cereales secos y las proteínas crudas; mezcla con tomate, cebolla y el resto del relleno.', 'Rellena los pimientos, rocía con aceite y hornea 25–35 minutos o hasta que estén tiernos y bien calientes.'],
 ['Preheat oven to 190°C/375°F; halve bell peppers and remove seeds.', 'Cook any dry grains and raw proteins separately; mix with tomato, onion and remaining filling.', 'Stuff the peppers, drizzle with oil and bake 25–35 minutes until tender and heated through.'], '''Pimientos rellenos de quinoa y garbanzos|Quinoa chickpea stuffed peppers|quinoa:120,chickpeas:175
Pimientos rellenos de arroz y pollo|Chicken rice stuffed peppers|rice:125,chicken:190
Pimientos rellenos de carne y lentejas|Beef lentil stuffed peppers|groundBeef:180,lentils:175
Pimientos rellenos de atún y papa|Tuna potato stuffed peppers|tuna:180,potatoes:245
Pimientos rellenos de tofu y champiñones|Tofu mushroom stuffed peppers|tofu:190,mushrooms:160
Pimientos rellenos de habichuelas y queso|Black bean cheese stuffed peppers|blackBeans:220,cheese:65
Pimientos rellenos de arroz y espinaca|Rice spinach stuffed peppers|rice:130,spinach:125''')
group('dinner','baked-potato','potatoes:520,oliveOil:10,salt:3','Papas asadas con relleno abundante.','Baked potatoes with a generous topping.',
 ['Precalienta el horno a 200 °C, lava y pincha las papas; hornea hasta que queden tiernas.', 'Mientras tanto, prepara el relleno: cocina por completo cualquier proteína cruda y ablanda los vegetales duros.', 'Abre las papas, reparte el relleno y termina con aceite o complementos indicados; sirve una porción por persona.'],
 ['Preheat oven to 200°C/390°F, scrub and prick the potatoes; bake until tender.', 'Meanwhile prepare the filling: fully cook any raw protein and soften firm vegetables.', 'Split potatoes, divide topping and finish with listed additions; serve one portion per person.'], '''Papa asada con atún y yogur|Tuna yogurt baked potatoes|tuna:190,yogurt:90,cucumber:100
Papa asada con pollo y brócoli|Chicken broccoli baked potatoes|chicken:220,broccoli:180
Papa asada con habichuelas negras|Black bean baked potatoes|blackBeans:250,tomatoes:125
Papa asada con queso y champiñones|Mushroom cheese baked potatoes|cheese:85,mushrooms:170
Papa asada con garbanzos y espinaca|Chickpea spinach baked potatoes|chickpeas:210,spinach:115
Papa asada con carne molida y tomate|Beef tomato baked potatoes|groundBeef:220,tomatoes:170
Papa asada con huevo y pimiento|Egg pepper baked potatoes|eggs:3,bellPepper:155''')
group('dinner','sweet-potato','sweetPotato:420,oliveOil:11,onion:75','Batata tierna convertida en una cena completa.','Tender sweet potato turned into a full dinner.',
 ['Corta la batata en cubos y hornéala a 200 °C con aceite hasta que esté tierna; también puedes hervirla.', 'Prepara el resto del plato: saltea los vegetales y cocina completamente la carne, el pollo o los huevos cuando corresponda.', 'Combina la batata con el acompañamiento y reparte en dos bowls.'],
 ['Dice sweet potato and roast at 200°C/390°F with oil until tender, or boil instead.', 'Prepare the additions: sauté vegetables and thoroughly cook meat, chicken or eggs as needed.', 'Combine sweet potato with the other ingredients and serve in two bowls.'], '''Batata con pollo y espinaca|Chicken spinach sweet potato bowl|chicken:220,spinach:120
Batata con tofu y brócoli|Tofu broccoli sweet potato bowl|tofu:230,broccoli:185
Batata con garbanzos y tomate|Chickpea tomato sweet potato bowl|chickpeas:235,tomatoes:170
Batata con carne molida y pimiento|Beef pepper sweet potato bowl|groundBeef:225,bellPepper:155
Batata con huevo y aguacate|Egg avocado sweet potato bowl|eggs:3,avocado:1
Batata con lentejas y champiñones|Lentil mushroom sweet potato bowl|lentils:235,mushrooms:155
Batata con atún y pepino|Tuna cucumber sweet potato bowl|tuna:185,cucumber:140''')
group('dinner','tomato-eggs','eggs:4,tomatoes:350,oliveOil:13,onion:100,garlic:7','Huevos cocinados en salsa de tomate aromática.','Eggs gently cooked in a fragrant tomato sauce.',
 ['Calienta el aceite; sofríe cebolla y ajo y añade el tomate picado hasta que espese.', 'Agrega los vegetales, legumbres u otros acompañamientos; cocina hasta que estén tiernos.', 'Forma huecos, rompe los huevos y tapa la sartén hasta que las claras y yemas cuajen por completo; sirve dos porciones.'],
 ['Heat oil; sauté onion and garlic and simmer chopped tomato until thick.', 'Add vegetables, beans and other additions; cook until tender.', 'Make wells, crack in eggs and cover until whites and yolks are fully set; divide into two servings.'], '''Huevos en tomate con espinaca|Spinach tomato skillet eggs|spinach:140
Huevos en tomate con pimiento|Pepper tomato skillet eggs|bellPepper:185
Huevos en tomate con garbanzos|Chickpea tomato skillet eggs|chickpeas:230
Huevos en tomate con champiñones|Mushroom tomato skillet eggs|mushrooms:200
Huevos en tomate con queso|Cheese tomato skillet eggs|cheese:75
Huevos en tomate con habichuelas negras|Black bean tomato skillet eggs|blackBeans:230
Huevos en tomate con calabacín|Zucchini tomato skillet eggs|zucchini:205''')
group('dinner','quinoa-dinner','quinoa:140,oliveOil:13,onion:80,garlic:8','Cena de quinoa con verduras y proteína.','Quinoa with vegetables and protein for dinner.',
 ['Enjuaga y cocina la quinoa en agua; tapa y deja reposar.', 'En una sartén con aceite cocina cebolla, ajo y verduras; cocina aparte por completo cualquier proteína animal cruda.', 'Añade los complementos y quinoa cocida, mezcla con cuidado y reparte en dos bowls.'],
 ['Rinse and cook quinoa in water, then cover and rest.', 'In oil, cook onion, garlic and vegetables; separately and fully cook any raw animal protein.', 'Add remaining ingredients and cooked quinoa, toss gently and divide into two bowls.'], '''Quinoa con pollo y brócoli|Chicken broccoli quinoa skillet|chicken:230,broccoli:180
Quinoa con tofu y espinaca|Tofu spinach quinoa skillet|tofu:240,spinach:125
Quinoa con atún y tomate|Tuna tomato quinoa skillet|tuna:200,tomatoes:195
Quinoa con garbanzos y calabacín|Chickpea zucchini quinoa skillet|chickpeas:240,zucchini:180
Quinoa con carne y pimiento|Beef pepper quinoa skillet|groundBeef:220,bellPepper:155
Quinoa con lentejas y zanahoria|Lentil carrot quinoa skillet|lentils:250,carrot:145
Quinoa con champiñones y queso|Mushroom cheese quinoa skillet|mushrooms:205,cheese:75''')
group('dinner','lentil-soup','lentils:390,vegetableStock:700,onion:85,carrot:125,oliveOil:10','Sopa sustanciosa de lentejas cocidas y vegetales.','A hearty soup made with cooked lentils and vegetables.',
 ['Pica cebolla, zanahoria y los vegetales adicionales.', 'Sofríe con aceite la cebolla y los vegetales firmes; añade caldo y lentejas ya cocidas.', 'Cocina a hervor suave hasta que los ingredientes estén tiernos; incorpora los más delicados al final y sirve en dos tazones.'],
 ['Chop onion, carrot and any additional vegetables.', 'Sauté onion and firmer vegetables in oil; add broth and already-cooked lentils.', 'Simmer until tender, add delicate ingredients toward the end and divide between two bowls.'], '''Sopa de lentejas con papa|Potato lentil soup|potatoes:270,garlic:8
Sopa de lentejas con espinaca|Spinach lentil soup|spinach:150,tomatoes:130
Sopa de lentejas con brócoli|Broccoli lentil soup|broccoli:200,garlic:9
Sopa de lentejas con batata|Sweet potato lentil soup|sweetPotato:260,celery:100
Sopa de lentejas con calabacín|Zucchini lentil soup|zucchini:225,tomatoes:140
Sopa de lentejas con champiñones|Mushroom lentil soup|mushrooms:200,herbs:9
Sopa de lentejas con quinoa|Quinoa lentil soup|quinoa:100,spinach:85''')

assert len(F)==28,len(F)
assert collections.Counter(x['slot'] for x in F)=={'breakfast':10,'lunch':10,'dinner':8}
assert sum(len(g['variants']) for g in F)==196,sum(len(g['variants']) for g in F)

new=[]; original_ids={r['id'] for r in existing};titles={lang:set(r[lang]['title'].lower() for r in existing) for lang in ('es','en')}
for g in F:
 for title_es,title_en,extra in g['variants']:
  assert title_es.lower() not in titles['es'] and title_en.lower() not in titles['en'],(title_es,title_en)
  titles['es'].add(title_es.lower());titles['en'].add(title_en.lower())
  id=slug(title_en)
  if id in original_ids or id in {r['id'] for r in new}: id='miga-'+id
  b=dict(g['base']);b.update(extra)
  amounts=[{'ingredient':k,'amount':q,'unit':units[k],**({'grams_per_piece':piece_g[k]} if units[k]=='pieces' else {})} for k,q in b.items()]
  cost=price_rows(amounts);cost['per_serving_cents']=int(math.floor(cost['total_cents']/2+.5))
  # No invented image URLs / placeholder assets. Pending photo intentionally prevents import.
  entry={'id':id,'slot':g['slot'],'minutes':(10 if g['kind'] in ('smoothie','yogurt','toast') else 15 if g['kind'] in ('scramble','omelette','sandwich','quesadilla','wrap','chickpea-salad') else 20 if g['kind'] in ('overnight',) else 25 if g['kind'] in ('porridge','pasta-salad','tofu-wok','tomato-eggs') else 30 if g['kind'] in ('chicken-rice','tuna-grain','veggie-rice','pasta-skillet','lentil-bowl','hash','beef-skillet','quinoa-dinner') else 40 if g['kind'] in ('chicken-soup','lentil-soup','sweet-potato') else 50 if g['kind'] in ('salmon-tray','stuffed-pepper','baked-potato') else 30),
  'servings':2,'sort_order':len(existing)+len(new),'photo':None,'photo_status':'pending_generation',
  'nutrition':nutrition_calc(amounts,2), 'amounts':amounts,
  'es':{'title':title_es,'description':g['desc_es'],'ingredients':[qty(a,'es') for a in amounts], 'steps':g['steps_es']},
  'en':{'title':title_en,'description':g['desc_en'],'ingredients':[qty(a,'en') for a in amounts], 'steps':g['steps_en']},
  'tags':['miga-expanded','photo-pending'],'source':'miga-editorial-2026-11','estimated_cost':cost}
  if g['kind']=='overnight': entry['minutes']=10;entry['es']['description']+=' Requiere al menos 6 horas de reposo.'; entry['en']['description']+=' Needs at least 6 hours of chilling.'
  # Precook starchy add-ins when the family's method does not already handle them.
  needs=[]
  for starch in ('rice','quinoa','pasta','potatoes','sweetPotato'):
   if starch in extra:
    handled={'rice':['veggie-rice','chicken-rice','stuffed-pepper','chicken-soup'],
             'quinoa':['tuna-grain','quinoa-dinner','stuffed-pepper','chicken-soup'],
             'pasta':['pasta-skillet','pasta-salad'],
             'potatoes':['hash','baked-potato','chicken-soup','salmon-tray'],
             'sweetPotato':['sweet-potato','chicken-soup','salmon-tray']}.get(starch,[])
    if g['kind'] not in handled: needs.append(starch)
  if needs:
   es_names=', '.join(labels[k][0] for k in needs)
   en_names=', '.join(labels[k][1] for k in needs)
   entry['es']['steps'].insert(0,f'Antes de empezar, cocina {es_names} por separado en agua hasta que esté tierno; escurre y reserva.')
   entry['en']['steps'].insert(0,f'Before starting, cook {en_names} separately in water until tender; drain and set aside.')
  if g['kind']=='baked-potato': entry['minutes']=70
  new.append(entry)
assert len(new)==196
assert len({r['id'] for r in existing+new})==250

# Price all 54 already-owned recipes as well; do NOT alter their stable recipe identities / old photos.
priced_existing=[]
for r in existing:
 x=json.loads(json.dumps(r));x['estimated_cost']=price_rows(x['amounts']); x['estimated_cost']['per_serving_cents']=int(math.floor(x['estimated_cost']['total_cents']/x['servings']+.5))
 priced_existing.append(x)
all250=priced_existing+new
assert all(r['estimated_cost']['lines'] and r['estimated_cost']['per_serving_cents']>0 for r in all250)

(CAT/'recipe-expansion-drafts.json').write_text(json.dumps({'schema_version':1,'publication_ready':False,'status':'editorial_draft','recipes':new},indent=2,ensure_ascii=False)+'\n')
(CAT/'recipes-250-staging.json').write_text(json.dumps({'schema_version':1,'publication_ready':False,'status':'editorial_draft','recipes':all250},indent=2,ensure_ascii=False)+'\n')
(CAT/'estimated-ingredient-prices-DOP.json').write_text(json.dumps({'currency':'DOP','as_of':'2026-11-01','market':'Dominican Republic','kind':'budget_estimate','basis':'portion-used; not a live supermarket quote','rates_per_canonical_unit':{k:{'unit':units[k], 'rate_dop':v,'es':labels[k][0],'en':labels[k][1]} for k,v in rates.items()},'grounding':['ProConsumidor SIDIP 23-09-2026, representative items','Ministerio de Agricultura 20-03-2026, representative staples','Retail observed examples; other rates assumptions']},ensure_ascii=False,indent=2)+'\n')
with (CAT/'recipes-250-prices-DOP.csv').open('w',newline='',encoding='utf-8-sig') as f:
 writer=csv.writer(f);writer.writerow(['id','category','title_es','title_en','servings','minutes','estimated_cost_total_DOP','estimated_cost_per_serving_DOP','photo_status','ingredient_count'])
 for r in all250:
  c=r['estimated_cost'];writer.writerow([r['id'],r['slot'],r['es']['title'],r['en']['title'],r['servings'],r['minutes'],f"{c['total_cents']/100:.2f}",f"{c['per_serving_cents']/100:.2f}",'ready' if r['photo'] else 'pending',len(r['amounts'])])
with (CAT/'recipes-250-ingredient-costs-DOP.csv').open('w',newline='',encoding='utf-8-sig') as f:
 writer=csv.writer(f);writer.writerow(['recipe_id','recipe_es','ingredient_key','ingredient_es','quantity','unit','estimated_unit_price_DOP','estimated_line_cost_DOP'])
 for r in all250:
  for l in r['estimated_cost']['lines']:
   writer.writerow([r['id'],r['es']['title'],l['ingredient'],labels[l['ingredient']][0],l['amount'],l['unit'],f"{l['unit_price_dop']:.3f}",f"{l['estimated_total_cents']/100:.2f}"])
print('created',len(existing),len(new),len(all250),'by slot',collections.Counter(r['slot'] for r in all250))
print('price per serving min/max',min(r['estimated_cost']['per_serving_cents'] for r in all250)/100,max(r['estimated_cost']['per_serving_cents'] for r in all250)/100)
print('price missing',sum(not r.get('estimated_cost') for r in all250))
print('images new pending',sum(not r['photo'] for r in all250),'known',sum(bool(r['photo']) for r in all250))
