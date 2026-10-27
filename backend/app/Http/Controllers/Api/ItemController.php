<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiError;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Item;
use App\Support\Api;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ItemController extends Controller
{
    /** Newest 150 items, or every item of ?donorId=. */
    public function index(Request $request)
    {
        $query = Item::query();
        if ($donor = $request->query('donorId')) {
            $query->where('donor_id', $donor);
        } else {
            $query->limit(150);
        }
        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        return response()->json($query->orderByDesc('created_at')->get()->map->toApi()->values());
    }

    public function show(string $id)
    {
        $item = Item::find($id) ?? throw ApiError::notFound('Item not found.');

        return response()->json($item->toApi());
    }

    public function store(Request $request)
    {
        $user = $request->user();
        if (! $user->canDonate()) {
            throw ApiError::forbidden($user->is_banned ? 'Your account is suspended.' : 'Your role cannot share items.');
        }
        $data = $request->validate([
            'id' => ['sometimes', 'string', 'regex:/^[A-Za-z0-9_-]{6,64}$/'],
            'title' => ['required', 'string', 'min:3', 'max:80'],
            'description' => ['required', 'string', 'min:1', 'max:1000'],
            'categoryId' => ['required', 'string', Rule::in($this->categoryIds())],
            'condition' => ['required', Rule::in(Item::CONDITIONS)],
            'images' => ['sometimes', 'array', 'max:5'],
            'images.*' => ['string', 'max:500'],
            'district' => ['required', 'string', 'max:40'],
            'city' => ['sometimes', 'nullable', 'string', 'max:80'],
        ]);
        if (Api::looksLikeSale($data['title'].' '.$data['description'])) {
            throw ApiError::invalid(Api::SALE_MESSAGE, 'looks-like-sale');
        }
        $id = $data['id'] ?? Str::random(20);
        if (Item::whereKey($id)->exists()) {
            throw ApiError::conflict('An item with this id already exists.');
        }

        $item = Item::create([
            'id' => $id,
            'donor_id' => $user->id,
            'title' => trim($data['title']),
            'description' => trim($data['description']),
            'category_id' => $data['categoryId'],
            'condition' => $data['condition'],
            'images' => array_map([Api::class, 'storedFilePath'], $data['images'] ?? []),
            'district' => $data['district'],
            'city' => trim($data['city'] ?? ''),
            'status' => 'available',
            'request_count' => 0,
        ]);

        return response()->json($item->toApi(), 201);
    }

    /** Donor (or admin) changes status: available / reserved / donated / removed. */
    public function setStatus(Request $request, string $id)
    {
        $item = Item::find($id) ?? throw ApiError::notFound('Item not found.');
        $user = $request->user();
        if ($item->donor_id !== $user->id && ! $user->isAdmin()) {
            throw ApiError::forbidden('Only the donor can change this item.');
        }
        $data = $request->validate(['status' => ['required', Rule::in(Item::STATUSES)]]);
        $item->update(['status' => $data['status']]);

        return response()->json($item->toApi());
    }

    private function categoryIds(): array
    {
        $ids = Category::pluck('id')->all();

        return $ids ?: ['books', 'school', 'clothes', 'shoes', 'electronics', 'household', 'other'];
    }
}
