<?php

namespace Tests\Unit;

use App\Support\Api;
use PHPUnit\Framework\TestCase;

class AntiResellTest extends TestCase
{
    public function test_detects_sale_wording(): void
    {
        foreach (['Rs. 500 only', 'price negotiable', 'for sale', 'selling my bike', '2000 LKR', 'රු 500'] as $text) {
            $this->assertTrue(Api::looksLikeSale($text), $text);
        }
    }

    public function test_allows_free_giving(): void
    {
        foreach (['Free school books', 'Kids shoes size 4', 'Priceless memories', 'Grade 10 maths'] as $text) {
            $this->assertFalse(Api::looksLikeSale($text), $text);
        }
    }
}
