<?php

namespace Database\Seeders;

use App\Models\AppNotification;
use App\Models\Item;
use App\Models\Need;
use App\Models\Review;
use App\Models\ShareRequest;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;

/**
 * A lived-in demo community: 12 members across Sri Lanka, 25 give-away posts
 * with photos, open needs, requests in every state, reviews, leaderboards and
 * notifications.
 *
 *   php artisan migrate:fresh --seed && php artisan db:seed --class=DemoSeeder
 *
 * Sign in as  +94 77 000 0001 (Nimal) or +94 77 000 0002 (Kavya), code 123456.
 * Photos: database/seeders/demo-photos/*.jpg (run download.bat there first);
 * items whose photo is missing simply show the category placeholder.
 */
class DemoSeeder extends Seeder
{
    /** @var array<string, User> */
    private array $u = [];

    public function run(): void
    {
        $this->call(CategorySeeder::class);
        $this->users();
        // Re-running starts the activity over (items reset their counters below).
        AppNotification::whereIn('user_id', collect($this->u)->pluck('id'))->delete();
        $items = $this->items();
        $this->needs();
        $this->activity($items);
    }

    // ---------------------------------------------------------------- users

    private function users(): void
    {
        $month = User::monthKeyNow();
        // key, phone, name, district, role, donations, this month, requests, rating
        $people = [
            ['nimal', '+94770000001', 'Nimal Perera', 'Colombo', 'both', 7, 2, 4, 4.8],
            ['kavya', '+94770000002', 'Kavya Silva', 'Gampaha', 'both', 3, 1, 6, 4.6],
            ['tharindu', '+94770000003', 'Tharindu Jayasinghe', 'Kandy', 'donor', 27, 5, 0, 4.9],
            ['fathima', '+94770000004', 'Fathima Rizwan', 'Colombo', 'both', 9, 3, 5, 4.7],
            ['sanduni', '+94770000005', 'Sanduni Wickramasinghe', 'Galle', 'donor', 14, 4, 1, 5.0],
            ['kasun', '+94770000006', 'Kasun Bandara', 'Kurunegala', 'requester', 0, 0, 7, 4.5],
            ['priya', '+94770000007', 'Priya Sivakumar', 'Jaffna', 'both', 11, 2, 3, 4.8],
            ['dinesh', '+94770000008', 'Dinesh Fernando', 'Gampaha', 'donor', 6, 1, 0, 4.4],
            ['malsha', '+94770000009', 'Malsha Herath', 'Matara', 'requester', 0, 0, 4, 4.9],
            ['ahamed', '+94770000010', 'Ahamed Nazeer', 'Batticaloa', 'both', 5, 0, 2, 4.6],
            ['chamari', '+94770000011', 'Chamari Dissanayake', 'Anuradhapura', 'donor', 52, 6, 0, 4.9],
            ['ruwan', '+94770000012', 'Ruwan Kumara', 'Ratnapura', 'requester', 0, 0, 3, 4.7],
        ];
        foreach ($people as $i => [$key, $phone, $name, $district, $role, $don, $monthDon, $req, $rating]) {
            $this->u[$key] = User::updateOrCreate(['phone' => $phone], [
                'display_name' => $name,
                'district' => $district,
                'role' => $role,
                'language' => 'en',
                'badges' => [],
                'donation_count' => $don,
                'month_key' => $monthDon > 0 ? $month : '2026-9',
                'month_donations' => $monthDon > 0 ? $monthDon : 2,
                'request_count' => $req,
                'rating' => $rating,
                'profile_completed_at' => now()->subDays(60 - $i * 3),
                'last_active_at' => now()->subHours($i),
                'created_at' => now()->subDays(60 - $i * 3),
            ]);
        }
    }

    // ---------------------------------------------------------------- items

    /** @return array<string, Item> */
    private function items(): array
    {
        // key, donor, title, description, category, condition, district, city, photo, hours ago, status
        $rows = [
            ['ol_books', 'tharindu', 'O/L Science & Maths textbooks (Gr 10–11)', "Complete set of government Science and Maths textbooks for Grades 10 and 11, plus my own short notes. A few pencil marks, otherwise clean. Perfect for someone sitting O/L next year.", 'books', 'good', 'Kandy', 'Peradeniya', 'textbooks', 3, 'available'],
            ['story_books', 'sanduni', 'Sinhala & English story books (15 books)', "Bedtime story books my kids have outgrown — Mahagedara series, Ladybird classics and a few picture books. Great for ages 4–8.", 'books', 'good', 'Galle', 'Hikkaduwa', 'storybooks', 7, 'available'],
            ['dictionary', 'priya', 'English–Tamil–Sinhala dictionary', "Trilingual dictionary, hardly used. Ideal for a student learning English.", 'books', 'new', 'Jaffna', 'Nallur', 'dictionary', 30, 'available'],
            ['backpack', 'fathima', 'Blue school backpack', "Strong blue backpack with two compartments and a water bottle pocket. Used for one school year, washed and clean.", 'school', 'good', 'Colombo', 'Dehiwala', 'backpack', 5, 'available'],
            ['stationery', 'chamari', 'Exercise books & stationery set', "20 unused exercise books (single ruled and square ruled), pens, erasers and rulers. Collected for a school drive — please take what your child needs.", 'school', 'new', 'Anuradhapura', 'Mihintale', 'stationery', 2, 'available'],
            ['pencils', 'dinesh', 'Colour pencils & art supplies', "Box of 36 colour pencils, a sketch book and crayons. Slightly used.", 'school', 'good', 'Gampaha', 'Negombo', 'pencils', 20, 'available'],
            ['calculator', 'tharindu', 'Casio fx-991 scientific calculator', "Works perfectly — used for A/L Combined Maths. Comes with its cover.", 'electronics', 'good', 'Kandy', 'Katugastota', 'calculator', 46, 'reserved'],
            ['kids_clothes', 'nimal', "Kids' clothes bundle (age 4–6)", "About 15 pieces: T-shirts, shorts, two frocks and a jumper. All washed and ironed. Our daughter grew out of them.", 'clothes', 'good', 'Colombo', 'Nugegoda', 'kidsclothes', 9, 'available'],
            ['office_shirts', 'dinesh', "Men's office shirts (size M, 5 pcs)", "Long-sleeve formal shirts in white, blue and striped. Good for someone starting a new job.", 'clothes', 'good', 'Gampaha', 'Ja-Ela', 'shirts', 26, 'available'],
            ['white_shirts', 'kavya', 'White school shirts (age 12–14)', "Three white school shirts, used for one term. Name labels removed.", 'clothes', 'used', 'Gampaha', 'Kadawatha', 'whiteshirt', 14, 'available'],
            ['saree', 'priya', 'Blue silk saree (worn once)', "Beautiful blue saree worn once for a wedding. Blouse not included.", 'clothes', 'new', 'Jaffna', 'Chavakachcheri', 'saree', 52, 'available'],
            ['sneakers', 'ahamed', 'Sports shoes size 42', "Comfortable running shoes, used for a few months. Clean soles, no tears.", 'shoes', 'good', 'Batticaloa', 'Kattankudy', 'sneakers', 18, 'available'],
            ['boots', 'sanduni', 'Formal black shoes size 41', "Hardly worn leather office shoes — bought the wrong size.", 'shoes', 'new', 'Galle', 'Galle Fort', 'boots', 70, 'available'],
            ['sandals', 'fathima', 'Leather sandals size 38', "Brown leather sandals, comfortable for daily wear.", 'shoes', 'used', 'Colombo', 'Wellawatte', 'sandals', 33, 'available'],
            ['laptop', 'chamari', 'Laptop for a student (older, works fine)', "Core i5 laptop with charger, 8 GB RAM. Battery lasts about 2 hours. Good for homework, Zoom classes and typing.", 'electronics', 'used', 'Anuradhapura', 'Anuradhapura Town', 'laptop', 4, 'available'],
            ['fan', 'nimal', 'Table fan (3 speeds)', "16-inch table fan, all three speeds work. We moved to a place with ceiling fans.", 'electronics', 'good', 'Colombo', 'Maharagama', 'fan', 60, 'donated'],
            ['desk_lamp', 'tharindu', 'LED study desk lamp', "Adjustable LED desk lamp — great for studying at night during power cuts (USB rechargeable).", 'electronics', 'good', 'Kandy', 'Kandy City', 'desklamp', 12, 'available'],
            ['chairs', 'chamari', 'Plastic chairs (set of 4)', "Four sturdy plastic chairs. Perfect for a small shop, a dansala or a home.", 'household', 'used', 'Anuradhapura', 'Kekirawa', 'chairs', 28, 'available'],
            ['pots', 'kavya', 'Pots & pans set', "Aluminium pots (3 sizes), a frying pan and a few spoons. Good for a new home or a boarding place.", 'household', 'good', 'Gampaha', 'Kiribathgoda', 'pots', 40, 'available'],
            ['baby_cot', 'sanduni', 'Baby cot mobile & nursery toys', "Soft hanging cot mobile and a few nursery toys, all washed. Can be collected from Galle.", 'household', 'good', 'Galle', 'Karapitiya', 'babycot', 22, 'available'],
            ['bedsheets', 'nimal', 'Bedsheets & pillow covers', "Two double bedsheets and four pillow covers, freshly washed.", 'household', 'good', 'Colombo', 'Kotte', 'bedsheets', 75, 'reserved'],
            ['bicycle', 'dinesh', 'Kids bicycle (age 6–9)', "Pink kids bicycle with training wheels. Tyres recently replaced.", 'other', 'good', 'Gampaha', 'Wattala', 'bicycle', 1, 'available'],
            ['cricket', 'ahamed', 'Cricket bat & balls', "Size 5 cricket bat and three tennis balls for the kids in the lane.", 'other', 'used', 'Batticaloa', 'Eravur', 'cricket', 36, 'available'],
            ['old_laptop_bag', 'priya', 'Grade 5 scholarship past papers', "Bundle of Grade 5 scholarship past papers and model papers (2018–2025), some answered in pencil.", 'books', 'used', 'Jaffna', 'Point Pedro', 'textbooks', 64, 'available'],
            ['uniform_shoes', 'fathima', 'Black school shoes size 4', "Black school shoes worn for one term. Polished and ready.", 'shoes', 'good', 'Colombo', 'Kolonnawa', 'boots', 16, 'available'],
        ];

        $items = [];
        foreach ($rows as [$key, $donor, $title, $desc, $cat, $cond, $district, $city, $photo, $hoursAgo, $status]) {
            $id = 'demo'.str_pad(substr(md5($key), 0, 16), 16, '0');
            $created = now()->subHours($hoursAgo);
            $items[$key] = Item::updateOrCreate(['id' => $id], [
                'donor_id' => $this->u[$donor]->id,
                'title' => $title,
                'description' => $desc,
                'category_id' => $cat,
                'condition' => $cond,
                'images' => $this->photo($photo, $id),
                'district' => $district,
                'city' => $city,
                'status' => $status,
                'request_count' => 0,
                'created_at' => $created,
                'updated_at' => $created,
            ]);
        }

        return $items;
    }

    /** Copies demo-photos/{name}.jpg to the public disk; returns the stored path(s). */
    private function photo(string $name, string $itemId): array
    {
        $source = __DIR__.'/demo-photos/'.$name.'.jpg';
        if (! is_file($source) || filesize($source) < 1000) {
            return [];
        }
        $path = "shareloop/items/{$itemId}/{$name}.jpg";
        Storage::disk('public')->put($path, file_get_contents($source));

        return ['/api/files/'.$path];
    }

    // ---------------------------------------------------------------- needs

    private function needs(): void
    {
        $rows = [
            ['kasun', 'School bag and shoes for Grade 6', 'Any colour is fine. Shoe size 3.', 'My son starts Grade 6 in January and we cannot afford a new bag after the floods.', 'school', 'Kurunegala', 'Kuliyapitiya', 6],
            ['malsha', 'A/L Biology textbooks', 'Grade 12–13 Biology, English or Sinhala medium.', 'I am sitting A/L next August and studying with borrowed books.', 'books', 'Matara', 'Weligama', 15],
            ['ruwan', 'Laptop for online classes', 'Anything that can run Zoom and Word.', 'My daughter attends online tuition on my phone — a laptop would help her a lot.', 'electronics', 'Ratnapura', 'Balangoda', 26],
            ['kavya', 'School bag for Grade 3', 'Any colour is fine.', 'My daughter starts at a new school next month.', 'school', 'Gampaha', 'Kadawatha', 40],
            ['priya', 'Baby clothes (0–6 months)', 'Boy or girl, both welcome.', 'Collecting for a young mother in our village who just had twins.', 'clothes', 'Jaffna', 'Kopay', 55],
            ['fathima', 'Wheelchair for my grandmother', 'Foldable if possible.', 'She had a fall and can no longer walk to the mosque.', 'other', 'Colombo', 'Maradana', 80],
            ['kasun', 'Study table and chair', 'Small is fine.', 'Three children share one small table to do homework.', 'household', 'Kurunegala', 'Kuliyapitiya', 100],
            ['malsha', 'Scientific calculator', 'Casio fx-82 or fx-991.', 'Needed for A/L Physics and Chemistry calculations.', 'electronics', 'Matara', 'Weligama', 120],
        ];
        foreach ($rows as [$who, $title, $desc, $reason, $cat, $district, $city, $hoursAgo]) {
            Need::updateOrCreate(['requester_id' => $this->u[$who]->id, 'title' => $title], [
                'description' => $desc,
                'reason' => $reason,
                'category_id' => $cat,
                'district' => $district,
                'city' => $city,
                'status' => 'open',
                'anti_resell_agreed' => true,
                'created_at' => now()->subHours($hoursAgo),
            ]);
        }
    }

    // ------------------------------------------------- requests, reviews, notifications

    /** @param array<string, Item> $items */
    private function activity(array $items): void
    {
        // item, requester, status, reason, hours ago, handover
        $requests = [
            // Nimal's kids clothes: two people asking — Nimal chooses on the demo
            ['kids_clothes', 'kavya', 'pending', 'My daughter is 5 and growing fast — these would really help us this year.', 6, null],
            ['kids_clothes', 'kasun', 'pending', 'For my two younger children, we lost most of their clothes in the floods.', 4, null],
            ['kids_clothes', 'priya', 'pending', 'Collecting for a family in our village with three small kids.', 2, null],
            // Nimal's bedsheets: accepted, handover chosen
            ['bedsheets', 'malsha', 'accepted', 'Moving into a boarding house near campus and have no bedding.', 70, 'courier'],
            // Nimal's fan: completed + reviews both ways
            ['fan', 'ruwan', 'completed', 'Our room gets very hot and my mother is unwell — a fan would help her sleep.', 58, 'direct'],
            ['fan', 'kasun', 'rejected', 'Need it for our small study room.', 57, null],
            // Nimal asked for things
            ['calculator', 'nimal', 'accepted', 'For my nephew who is starting A/L Combined Maths.', 44, 'on_demand'],
            ['laptop', 'nimal', 'pending', 'For a neighbour’s son who does online classes on a cracked phone.', 3, null],
            ['story_books', 'nimal', 'pending', 'Starting a small reading corner at our temple Daham Pasala.', 5, null],
            // Activity between others (for history / counters)
            ['ol_books', 'malsha', 'pending', 'I am sitting O/L in December — these would help a lot.', 2, null],
            ['ol_books', 'kasun', 'pending', 'For my eldest who starts Grade 10.', 1, null],
            ['stationery', 'ruwan', 'pending', 'For my daughter and two classmates who cannot afford books.', 1, null],
            ['chairs', 'fathima', 'pending', 'For the Quran class at our mosque.', 20, null],
            ['pots', 'malsha', 'pending', 'Setting up my first boarding room in Colombo.', 30, null],
            ['baby_cot', 'priya', 'pending', 'For the young mother with twins in our village.', 18, null],
        ];

        $made = [];
        foreach ($requests as [$itemKey, $who, $status, $reason, $hoursAgo, $handover]) {
            $item = $items[$itemKey];
            $requester = $this->u[$who];
            $at = now()->subHours($hoursAgo);
            $r = ShareRequest::updateOrCreate(['id' => ShareRequest::idFor($item->id, $requester->id)], [
                'item_id' => $item->id,
                'item_title' => $item->title,
                'donor_id' => $item->donor_id,
                'requester_id' => $requester->id,
                'message' => $reason,
                'anti_resell_agreed' => true,
                'handover_method' => $handover,
                'status' => $status,
                'created_at' => $at,
                'updated_at' => $status === 'pending' ? $at : $at->copy()->addHours(1),
            ]);
            $item->increment('request_count');
            $made[] = $r;
            $this->notificationsFor($r, $at);
        }

        // Reviews for the completed fan exchange (both directions)
        $fan = collect($made)->first(fn ($r) => $r->status === 'completed');
        $this->review($fan, $fan->requester_id, $fan->donor_id, 5, 'Very kind family, the fan works perfectly. Thank you so much!', 50);
        $this->review($fan, $fan->donor_id, $fan->requester_id, 5, 'On time and very polite. Happy it went to someone who needed it.', 49);

        // Older reviews so profiles have history
        $extra = [
            ['tharindu', 'kasun', 5, 'Got a full set of A/L books — my son is so happy. Highly recommended donor!'],
            ['tharindu', 'malsha', 5, 'Books were in great condition and he even added his notes.'],
            ['chamari', 'ruwan', 5, 'She donated 20 exercise books to our village school. Amazing person.'],
            ['sanduni', 'priya', 5, 'Beautiful baby clothes, carefully packed.'],
            ['fathima', 'kavya', 4, 'Friendly and quick to respond.'],
            ['nimal', 'kasun', 5, 'Nimal delivered the chairs himself. Thank you!'],
        ];
        foreach ($extra as $i => [$donor, $requester, $stars, $comment]) {
            $id = "demoreview{$i}_{$this->u[$requester]->id}";
            Review::updateOrCreate(['id' => $id], [
                'request_id' => "demoreview{$i}",
                'reviewer_id' => $this->u[$requester]->id,
                'reviewee_id' => $this->u[$donor]->id,
                'rating' => $stars,
                'comment' => $comment,
                'created_at' => now()->subDays(10 + $i * 4),
            ]);
        }

        // A donor answered one of Kavya's needs
        $kavyaNeed = Need::where('requester_id', $this->u['kavya']->id)->first();
        AppNotification::create([
            'user_id' => $this->u['kavya']->id,
            'sender_id' => $this->u['fathima']->id,
            'type' => 'need_match',
            'title' => 'Someone has what you need 🎁',
            'body' => '"Blue school backpack" was shared for your request "'.$kavyaNeed->title.'"',
            'need_id' => $kavyaNeed->id,
            'item_id' => $items['backpack']->id,
            'read' => false,
            'created_at' => now()->subHours(5),
        ]);
    }

    private function notificationsFor(ShareRequest $r, Carbon $at): void
    {
        $title = $r->item_title;
        $this->notify($r, $r->donor_id, $r->requester_id, 'new_request',
            'New request for your item', "Someone requested \"{$title}\"", $at, $r->status !== 'pending');

        $later = $at->copy()->addHours(1);
        match ($r->status) {
            'accepted' => $this->notify($r, $r->requester_id, $r->donor_id, 'request_accepted',
                'Request accepted 🎉', "Your request for \"{$title}\" was accepted. Contact details are now visible.", $later, false),
            'rejected' => $this->notify($r, $r->requester_id, $r->donor_id, 'request_rejected',
                'Request update', "\"{$title}\" went to another requester this time.", $later, true),
            'completed' => $this->notify($r, $r->requester_id, $r->donor_id, 'request_completed',
                'Donation completed', "Please rate your exchange for \"{$title}\"", $later, true),
            default => null,
        };
    }

    private function notify(ShareRequest $r, string $to, string $from, string $type, string $title, string $body, Carbon $at, bool $read): void
    {
        AppNotification::create([
            'user_id' => $to,
            'sender_id' => $from,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'request_id' => $r->id,
            'item_id' => $r->item_id,
            'read' => $read,
            'created_at' => $at,
            'updated_at' => $at,
        ]);
    }

    private function review(ShareRequest $r, string $from, string $to, int $stars, string $comment, int $hoursAgo): void
    {
        Review::updateOrCreate(['id' => $r->id.'_'.$from], [
            'request_id' => $r->id,
            'reviewer_id' => $from,
            'reviewee_id' => $to,
            'rating' => $stars,
            'comment' => $comment,
            'created_at' => now()->subHours($hoursAgo),
        ]);
    }
}
