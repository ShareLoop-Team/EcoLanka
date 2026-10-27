<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = [];

    protected function casts(): array
    {
        return ['name' => 'array', 'order' => 'integer'];
    }

    public function toApi(): array
    {
        return ['id' => $this->id, 'name' => $this->name, 'icon' => $this->icon, 'order' => $this->order];
    }
}
