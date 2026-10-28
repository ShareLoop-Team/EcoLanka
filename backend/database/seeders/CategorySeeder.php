<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

/** Keep ids in sync with lib/utils/helpers.dart (AppCategories). */
class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['books', 'menu_book', 'Educational Books', 'අධ්‍යාපනික පොත්', 'கல்விப் புத்தகங்கள்'],
            ['school', 'school', 'School Supplies', 'පාසල් උපකරණ', 'பள்ளி பொருட்கள்'],
            ['clothes', 'checkroom', 'Clothes', 'ඇඳුම්', 'ஆடைகள்'],
            ['shoes', 'shopping_bag', 'Shoes', 'සපත්තු', 'காலணிகள்'],
            ['electronics', 'devices', 'Electronics', 'ඉලෙක්ට්‍රොනික', 'மின்னணு சாதனங்கள்'],
            ['household', 'home', 'Household Items', 'ගෘහ භාණ්ඩ', 'வீட்டு பொருட்கள்'],
            ['other', 'category', 'Other', 'වෙනත්', 'மற்றவை'],
        ];
        foreach ($categories as $i => [$id, $icon, $en, $si, $ta]) {
            Category::updateOrCreate(['id' => $id], [
                'name' => ['en' => $en, 'si' => $si, 'ta' => $ta],
                'icon' => $icon,
                'order' => $i + 1,
            ]);
        }
    }
}
